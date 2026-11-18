import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:xml/xml.dart';

import '../models/imported_epub.dart';

/// Validates the container BEFORE decompressing. No disk extraction or network.
class EpubValidator {
  static const maxBytes = 20 * 1024 * 1024;
  static const maxExpanded = 80 * 1024 * 1024;
  static const maxEntry = 12 * 1024 * 1024;
  const EpubValidator();
  Never _fail(String message) => throw EpubFailure(message);

  void _zipBounds(Uint8List bytes) {
    final b = ByteData.sublistView(bytes);
    int u16(int p) => b.getUint16(p, Endian.little);
    int u32(int p) => b.getUint32(p, Endian.little);
    if (bytes.length < 22 || u32(0) != 0x04034b50) {
      _fail('El archivo no es un EPUB ZIP válido.');
    }
    var end = -1;
    for (var p = bytes.length - 22; p >= 0 && p >= bytes.length - 65557; p--) {
      if (u32(p) == 0x06054b50 && p + 22 + u16(p + 20) == bytes.length) {
        end = p;
        break;
      }
    }
    if (end < 0 ||
        u16(end + 4) != 0 ||
        u16(end + 6) != 0 ||
        u16(end + 8) != u16(end + 10)) {
      _fail('EPUB incompleto o ZIP multipartes no compatible.');
    }
    final count = u16(end + 10), offset = u32(end + 16), length = u32(end + 12);
    if (count == 0 || count > 1500 || offset + length != end) {
      _fail(
        'El EPUB supera los límites del contenedor o usa ZIP64 no compatible.',
      );
    }
    var p = offset, total = 0;
    final paths = <String>{};
    for (var i = 0; i < count; i++) {
      if (p + 46 > end || u32(p) != 0x02014b50) {
        _fail('El directorio ZIP está corrupto.');
      }
      final flags = u16(p + 8),
          method = u16(p + 10),
          compressed = u32(p + 20),
          expanded = u32(p + 24);
      final nameSize = u16(p + 28),
          extra = u16(p + 30),
          comment = u16(p + 32),
          local = u32(p + 42);
      if (p + 46 + nameSize + extra + comment > end || local + 30 > offset) {
        _fail('EPUB corrupto.');
      }
      if ((flags & 1) != 0) _fail('EPUB cifrado o con DRM no compatible.');
      if (method != 0 && method != 8) _fail('Compresión EPUB no compatible.');
      final name = utf8.decode(bytes.sublist(p + 46, p + 46 + nameSize));
      if (name.startsWith('/') ||
          name.contains('\\') ||
          name.contains(':') ||
          name.split('/').contains('..') ||
          !paths.add(name)) {
        _fail('El EPUB contiene rutas inseguras o duplicadas.');
      }
      total += expanded;
      if (expanded > maxEntry ||
          total > maxExpanded ||
          (expanded > 1024 * 1024 && expanded > (compressed + 1) * 200)) {
        _fail(
          'El contenido descomprimido del EPUB es excesivo (máximo 80 MiB).',
        );
      }
      if (u32(local) != 0x04034b50 ||
          u16(local + 8) != method ||
          u16(local + 6) != flags) {
        _fail('Cabeceras ZIP inconsistentes.');
      }
      final localName = u16(local + 26), localExtra = u16(local + 28);
      if (local + 30 + localName + localExtra + compressed > offset ||
          utf8.decode(bytes.sublist(local + 30, local + 30 + localName)) !=
              name) {
        _fail('Rutas ZIP inconsistentes.');
      }
      p += 46 + nameSize + extra + comment;
    }
    if (p != end ||
        u16(8) != 0 ||
        utf8.decode(bytes.sublist(30, 30 + u16(26))) != 'mimetype') {
      _fail('El EPUB debe comenzar con mimetype sin comprimir.');
    }
  }

  XmlDocument _xml(Uint8List data) {
    final text = utf8.decode(data);
    // External entities/DTD are never resolved; reject declarations proactively.
    if (RegExp(
      r'<!\s*(DOCTYPE|ENTITY)|<\?(?!xml\s)',
      caseSensitive: false,
    ).hasMatch(text)) {
      _fail('Este EPUB contiene declaraciones XML no compatibles.');
    }
    return XmlDocument.parse(text);
  }

  String _attribute(XmlElement element, String name) =>
      element.getAttribute(name) ?? '';
  String _resolve(String base, String href) {
    if (href.isEmpty ||
        Uri.parse(href).hasScheme ||
        href.startsWith('//') ||
        href.contains('\\')) {
      _fail('El EPUB contiene recursos externos o rutas no compatibles.');
    }
    final path = Uri.parse(base).resolve(href).path;
    if (path.startsWith('/') || path.split('/').contains('..')) {
      _fail('Ruta EPUB insegura.');
    }
    return Uri.decodeComponent(path);
  }

  String _bookHref(String opf, String target) {
    final base = opf.split('/')..removeLast();
    final parts = target.split('/');
    var shared = 0;
    while (shared < base.length &&
        shared < parts.length &&
        base[shared] == parts[shared]) {
      shared++;
    }
    return Uri(
      path: [
        ...List.filled(base.length - shared, '..'),
        ...parts.skip(shared),
      ].join('/'),
    ).toString();
  }

  void _safeMarkup(XmlDocument document) {
    const forbidden = {
      'script',
      'iframe',
      'frame',
      'frameset',
      'object',
      'embed',
      'form',
      'base',
      'foreignobject',
      'animate',
      'set',
      'audio',
      'video',
    };
    for (final element in document.descendants.whereType<XmlElement>()) {
      if (forbidden.contains(element.name.local.toLowerCase())) {
        _fail('EPUB con contenido activo o multimedia no compatible.');
      }
      if (element.name.local.toLowerCase() == 'meta' &&
          _attribute(element, 'http-equiv').isNotEmpty) {
        _fail('EPUB con redirección no compatible.');
      }
      for (final a in element.attributes) {
        final name = a.name.local.toLowerCase();
        if (name.startsWith('on') || name == 'srcdoc' || name == 'srcset') {
          _fail('EPUB con contenido activo no compatible.');
        }
        if (name == 'style') _safeCss(a.value);
        if ({
          'href',
          'src',
          'poster',
          'action',
          'data',
          'background',
        }.contains(name)) {
          final value = a.value.replaceAll(RegExp(r'[\x00-\x20]'), '');
          if (Uri.tryParse(value)?.hasScheme == true ||
              value.startsWith('//') ||
              value.contains('\\')) {
            _fail('Esta versión admite EPUB sin enlaces ni recursos externos.');
          }
        }
      }
      if (element.name.local.toLowerCase() == 'style') {
        _safeCss(element.innerText);
      }
    }
  }

  void _safeCss(String text) {
    // Reject CSS escapes/comments to prevent disguising active/remote URLs.
    if (text.contains('\\') ||
        text.contains('/*') ||
        RegExp(
          r'@import|expression\s*\(|behavior\s*:|-moz-binding|url\s*\(\s*["\x27]?\s*(?:[a-z][a-z0-9+.-]*:|//)',
          caseSensitive: false,
        ).hasMatch(text)) {
      _fail('EPUB con estilos activos o recursos remotos no compatible.');
    }
  }

  ValidatedEpub validate(Uint8List bytes, String fileName) {
    try {
      if (!fileName.toLowerCase().endsWith('.epub')) {
        _fail('Selecciona un archivo .epub.');
      }
      if (bytes.isEmpty) _fail('El archivo EPUB está vacío.');
      if (bytes.length > maxBytes) _fail('El EPUB supera el máximo de 20 MiB.');
      _zipBounds(bytes);
      final archive = ZipDecoder().decodeBytes(bytes, verify: true);
      final files = <String, Uint8List>{};
      var expanded = 0;
      for (final file in archive.files) {
        if (!file.isFile) continue;
        final data = file.readBytes();
        if (data == null || data.length != file.size) {
          _fail('El EPUB está corrupto o incompleto.');
        }
        expanded += data.length;
        if (data.length > maxEntry || expanded > maxExpanded) {
          _fail('El EPUB descomprimido supera el límite seguro.');
        }
        files[file.name] = data;
      }
      if (utf8.decode(files['mimetype'] ?? []) != 'application/epub+zip') {
        _fail('El archivo no declara el formato EPUB.');
      }
      if (files.keys.any(
        (p) => {
          'meta-inf/encryption.xml',
          'meta-inf/rights.xml',
        }.contains(p.toLowerCase()),
      )) {
        _fail('EPUB con DRM, cifrado u ofuscación no compatible.');
      }
      final container = _xml(files['META-INF/container.xml'] ?? Uint8List(0));
      final roots = container.descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local == 'rootfile')
          .toList();
      if (roots.length != 1) _fail('El EPUB debe contener un único libro.');
      final opfPath = _resolve('', _attribute(roots.single, 'full-path'));
      final opf = _xml(files[opfPath] ?? Uint8List(0));
      final package = opf.rootElement;
      if (package.name.local != 'package' ||
          !{'2.0', '3.0'}.contains(_attribute(package, 'version'))) {
        _fail('Versión EPUB no compatible.');
      }
      final elements = opf.descendants.whereType<XmlElement>().toList();
      String metadata(String key, String fallback) =>
          elements
              .where((e) => e.name.local == key)
              .map((e) => e.innerText.trim())
              .where((s) => s.isNotEmpty)
              .firstOrNull ??
          fallback;
      final manifest = <String, String>{};
      final types = <String, String>{};
      String? ncx, nav;
      for (final item in elements.where((e) => e.name.local == 'item')) {
        final id = _attribute(item, 'id'),
            href = _attribute(item, 'href'),
            type = _attribute(item, 'media-type');
        final path = _resolve(opfPath, href);
        if (id.isEmpty ||
            manifest.containsKey(id) ||
            !files.containsKey(path)) {
          _fail('El EPUB tiene recursos ausentes o duplicados.');
        }
        if (_attribute(item, 'properties').split(' ').contains('scripted')) {
          _fail('EPUB con scripts no compatible.');
        }
        manifest[id] = path;
        types[path] = type;
        if (type == 'application/x-dtbncx+xml') ncx = path;
        if (_attribute(item, 'properties').split(' ').contains('nav')) {
          nav = path;
        }
      }
      for (final entry in files.entries) {
        final path = entry.key.toLowerCase();
        if (path.endsWith('.js')) _fail('EPUB con scripts no compatible.');
        if (path.endsWith('.css')) _safeCss(utf8.decode(entry.value));
        if (RegExp(r'\.(xhtml|html|htm|svg)$').hasMatch(path) ||
            {
              'application/xhtml+xml',
              'image/svg+xml',
            }.contains(types[entry.key])) {
          if (entry.value.length > 4 * 1024 * 1024) {
            _fail('Un capítulo EPUB supera el límite de 4 MiB.');
          }
          _safeMarkup(_xml(entry.value));
        }
      }
      final spine = elements
          .where((e) => e.name.local == 'itemref')
          .where((e) => _attribute(e, 'linear') != 'no')
          .map((e) => manifest[_attribute(e, 'idref')])
          .toList();
      if (spine.isEmpty ||
          spine.any((p) => p == null || types[p] != 'application/xhtml+xml')) {
        _fail('El EPUB no contiene una secuencia de lectura válida.');
      }
      final chapters = <EpubTocItem>[];
      if (nav != null) {
        final doc = _xml(files[nav]!);
        for (final a in doc.descendants.whereType<XmlElement>().where(
          (e) => e.name.local == 'a',
        )) {
          final href = _attribute(a, 'href');
          final resolved = _resolve(nav, href);
          if (!files.containsKey(resolved)) {
            _fail('El índice EPUB apunta a contenido ausente.');
          }
          chapters.add(
            EpubTocItem(
              a.innerText.trim(),
              _bookHref(opfPath, resolved) +
                  (Uri.parse(href).hasFragment
                      ? '#${Uri.parse(href).fragment}'
                      : ''),
            ),
          );
        }
      } else if (ncx != null) {
        final doc = _xml(files[ncx]!);
        for (final point in doc.descendants.whereType<XmlElement>().where(
          (e) => e.name.local == 'navPoint',
        )) {
          final content = point.descendants
              .whereType<XmlElement>()
              .where((e) => e.name.local == 'content')
              .firstOrNull;
          final title = point.descendants
              .whereType<XmlElement>()
              .where((e) => e.name.local == 'text')
              .firstOrNull
              ?.innerText
              .trim();
          if (content == null) continue;
          final href = _attribute(content, 'src'),
              resolved = _resolve(ncx, href);
          if (!files.containsKey(resolved)) {
            _fail('El índice EPUB apunta a contenido ausente.');
          }
          chapters.add(
            EpubTocItem(
              title ?? 'Capítulo ${chapters.length + 1}',
              _bookHref(opfPath, resolved) +
                  (Uri.parse(href).hasFragment
                      ? '#${Uri.parse(href).fragment}'
                      : ''),
            ),
          );
        }
      }
      if (chapters.isEmpty) {
        for (final path in spine.cast<String>()) {
          chapters.add(
            EpubTocItem(
              'Capítulo ${chapters.length + 1}',
              _bookHref(opfPath, path),
            ),
          );
        }
      }
      if (chapters.length > 1500) _fail('Índice EPUB excesivo.');
      final book = ImportedEpub(
        id: sha256.convert(bytes).toString(),
        title: metadata('title', fileName),
        author: metadata('creator', 'Autor no indicado'),
        fileName: fileName
            .split(RegExp(r'[/\\]'))
            .last
            .replaceAll(RegExp(r'[\x00-\x1f]'), ''),
        size: bytes.length,
        chapters: chapters,
        createdAt: DateTime.now().toUtc().toIso8601String(),
      );
      return ValidatedEpub(book, Uint8List.fromList(bytes));
    } on EpubFailure {
      rethrow;
    } catch (_) {
      _fail('El EPUB está corrupto o utiliza contenido no compatible.');
    }
  }
}
