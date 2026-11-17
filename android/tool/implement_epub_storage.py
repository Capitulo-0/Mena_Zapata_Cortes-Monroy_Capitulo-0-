from pathlib import Path
files={
'lib/features/epub/data/epub_store.dart':r'''import 'dart:typed_data';
import '../models/imported_epub.dart';
import 'epub_store_stub.dart'
  if (dart.library.io) 'epub_store_native.dart'
  if (dart.library.js_interop) 'epub_store_web.dart' as platform;

abstract interface class EpubStore {
  Future<List<ImportedEpub>> list(String owner);
  Future<bool> contains(String owner, String id);
  Future<Uint8List?> read(String owner, String id);
  Future<void> insert(String owner, ImportedEpub book, Uint8List bytes);
  Future<void> update(String owner, ImportedEpub book);
  Future<void> remove(String owner, String id);
}
EpubStore createEpubStore() => platform.createStore();
''',
'lib/features/epub/data/epub_store_stub.dart':r'''import 'epub_store.dart';
EpubStore createStore() => throw UnsupportedError('Almacenamiento EPUB no disponible.');
''',
'lib/features/epub/data/epub_store_native.dart':r'''import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../models/imported_epub.dart';
import 'epub_store.dart';

EpubStore createStore() => NativeEpubStore();
class NativeEpubStore implements EpubStore {
  NativeEpubStore({this.baseDirectory});
  final Directory? baseDirectory;
  Future<Directory> _directory(String owner) async {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(owner)) throw const EpubFailure('Cuenta local no válida.');
    final base = baseDirectory ?? await getApplicationSupportDirectory();
    return Directory('${base.path}/imported_epubs_v1/$owner')..createSync(recursive: true);
  }
  void _id(String id) {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(id)) throw const EpubFailure('Identificador EPUB no válido.');
  }
  Future<File> _file(String owner,String id,String extension) async {
    _id(id); return File('${(await _directory(owner)).path}/$id.$extension');
  }
  @override
  Future<List<ImportedEpub>> list(String owner) async {
    final directory = await _directory(owner); final result = <ImportedEpub>[];
    await for (final file in directory.list(followLinks:false)) {
      if (file is File && file.path.endsWith('.json')) {
        result.add(ImportedEpub.fromJson(jsonDecode(await file.readAsString()) as Map<String,dynamic>));
      }
    }
    return result;
  }
  @override
  Future<bool> contains(String owner,String id) async => (await _file(owner,id,'epub')).exists();
  @override
  Future<Uint8List?> read(String owner,String id) async {
    final file = await _file(owner,id,'epub'); return await file.exists() ? file.readAsBytes() : null;
  }
  Future<void> _metadata(String owner, ImportedEpub book) async {
    final file = await _file(owner,book.id,'json');
    final temp = File('${file.path}.pending');
    await temp.writeAsString(jsonEncode(book.toJson()), flush:true);
    await temp.rename(file.path);
  }
  @override
  Future<void> insert(String owner,ImportedEpub book,Uint8List bytes) async {
    final file = await _file(owner,book.id,'epub'); final existed = await file.exists();
    final temp = File('${file.path}.pending');
    try {
      await temp.writeAsBytes(bytes,flush:true); await temp.rename(file.path);
      await _metadata(owner,book);
    } catch (_) {
      if (await temp.exists()) await temp.delete();
      if (!existed && await file.exists()) await file.delete();
      rethrow;
    }
  }
  @override
  Future<void> update(String owner,ImportedEpub book) async {
    if (!await contains(owner,book.id) || !await (await _file(owner,book.id,'json')).exists()) {
      throw const EpubFailure('La copia local ya no existe. Reimportar EPUB.');
    }
    await _metadata(owner,book);
  }
  @override
  Future<void> remove(String owner,String id) async {
    // Remove availability first; if metadata deletion fails the UI marks it missing.
    final file = await _file(owner,id,'epub'); if (await file.exists()) await file.delete();
    final meta = await _file(owner,id,'json'); if (await meta.exists()) await meta.delete();
  }
}
''',
'lib/features/epub/data/epub_store_web.dart':r'''import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import '../models/imported_epub.dart';
import 'epub_store.dart';
EpubStore createStore() => IndexedDbEpubStore();

class IndexedDbEpubStore implements EpubStore {
  Future<web.IDBDatabase>? _opening;
  Future<JSAny?> _request(web.IDBRequest request) {
    final result=Completer<JSAny?>();
    request.onsuccess=((web.Event e) { if (!result.isCompleted) result.complete(request.result); }).toJS;
    request.onerror=((web.Event e) { if (!result.isCompleted) result.completeError(const EpubFailure('No se pudo acceder al almacenamiento EPUB del navegador.')); }).toJS;
    return result.future;
  }
  Future<web.IDBDatabase> _db() => _opening ??= _open();
  Future<web.IDBDatabase> _open() async {
    try {
      final request=web.window.indexedDB.open('capitulo0-imported-epubs-v1',1);
      request.onupgradeneeded=((web.Event e) {
        final db=request.result as web.IDBDatabase;
        db.createObjectStore('records'); db.createObjectStore('files');
      }).toJS;
      request.onblocked=((web.Event e) {}).toJS;
      final db=await _request(request).timeout(const Duration(seconds:10));
      return db as web.IDBDatabase;
    } catch (_) { _opening=null; throw const EpubFailure('IndexedDB no está disponible. Permite almacenamiento local en este navegador.'); }
  }
  String _key(String owner,String id) {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(owner) || !RegExp(r'^[a-f0-9]{64}$').hasMatch(id)) throw const EpubFailure('Identificador local no válido.');
    return '$owner/$id';
  }
  Future<void> _commit(web.IDBTransaction transaction) {
    final result=Completer<void>();
    transaction.oncomplete=((web.Event e) { if(!result.isCompleted) result.complete(); }).toJS;
    void fail(web.Event e) { if(!result.isCompleted) result.completeError(const EpubFailure('No se guardó el EPUB. Revisa la cuota y los permisos de almacenamiento.')); }
    transaction.onabort=fail.toJS; transaction.onerror=fail.toJS;
    return result.future;
  }
  @override
  Future<List<ImportedEpub>> list(String owner) async {
    _key(owner,'0'*64);
    final tx=(await _db()).transaction('records'.toJS,'readonly');
    final range=web.IDBKeyRange.bound('$owner/'.toJS,'$owner/\uffff'.toJS);
    final result=await _request(tx.objectStore('records').getAll(range));
    return (result as JSArray<JSString>).toDart.map((s) => ImportedEpub.fromJson(jsonDecode(s.toDart) as Map<String,dynamic>)).toList();
  }
  @override
  Future<bool> contains(String owner,String id) async {
    final tx=(await _db()).transaction('files'.toJS,'readonly');
    final result=await _request(tx.objectStore('files').getKey(_key(owner,id).toJS));
    return result != null && !result.isUndefinedOrNull;
  }
  @override
  Future<Uint8List?> read(String owner,String id) async {
    final tx=(await _db()).transaction('files'.toJS,'readonly');
    final result=await _request(tx.objectStore('files').get(_key(owner,id).toJS));
    return result == null || result.isUndefinedOrNull ? null : Uint8List.fromList((result as JSUint8Array).toDart);
  }
  @override
  Future<void> insert(String owner,ImportedEpub book,Uint8List bytes) async {
    final key=_key(owner,book.id).toJS;
    final tx=(await _db()).transaction(['files'.toJS,'records'.toJS].toJS,'readwrite');
    final done=_commit(tx);
    tx.objectStore('files').put(bytes.toJS,key);
    tx.objectStore('records').put(jsonEncode(book.toJson()).toJS,key);
    await done;
  }
  @override
  Future<void> update(String owner,ImportedEpub book) async {
    final key=_key(owner,book.id).toJS;
    final tx=(await _db()).transaction(['files'.toJS,'records'.toJS].toJS,'readwrite');
    final done=_commit(tx);
    final request=tx.objectStore('records').getKey(key);
    request.onsuccess=((web.Event e) {
      final result=request.result;
      if (result == null || result.isUndefinedOrNull) { tx.abort(); return; }
      tx.objectStore('records').put(jsonEncode(book.toJson()).toJS,key);
    }).toJS;
    await done;
  }
  @override
  Future<void> remove(String owner,String id) async {
    final key=_key(owner,id).toJS;
    final tx=(await _db()).transaction(['files'.toJS,'records'.toJS].toJS,'readwrite');
    final done=_commit(tx);tx.objectStore('files').delete(key);tx.objectStore('records').delete(key);await done;
  }
}
''',
'lib/features/epub/data/epub_repository.dart':r'''import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../models/imported_epub.dart';
import 'epub_store.dart';
import 'epub_validator.dart';

class EpubRepository {
  EpubRepository({required String account,required this.store}) : owner=sha256.convert(utf8.encode('capitulo0-epub-v1:$account')).toString();
  final String owner;
  final EpubStore store;
  Future<List<ImportedEpub>> list() async {
    try {
      final records=await store.list(owner);final result=<ImportedEpub>[];
      for(final record in records) { result.add(record.position(fileAvailable:await store.contains(owner,record.id))); }
      result.sort((a,b) => b.createdAt.compareTo(a.createdAt));return result;
    } on EpubFailure { rethrow; } catch (_) { throw const EpubFailure('No pudimos recuperar tus EPUB locales. Revisa el almacenamiento.'); }
  }
  Future<ImportedEpub> import(ValidatedEpub source) async {
    try {
      final records=await list();
      final duplicate=records.where((r)=>r.id==source.book.id).firstOrNull;
      if(duplicate?.fileAvailable==true) return duplicate!;
      if(records.fold<int>(0,(n,b)=>n+b.size)+source.bytes.length>200*1024*1024) throw const EpubFailure('La colección local supera 200 MiB. Exporta y elimina algún EPUB.');
      final book=duplicate?.position(fileAvailable:true) ?? source.book;
      await store.insert(owner,book,source.bytes);return book;
    } on EpubFailure { rethrow; } catch (_) { throw const EpubFailure('El EPUB no quedó almacenado. Revisa espacio y permisos y vuelve a importarlo.'); }
  }
  Future<Uint8List> bytes(ImportedEpub book) async {
    try {
      final bytes=await store.read(owner,book.id);
      if(bytes==null) throw const EpubFailure('La copia local no existe. Reimportar EPUB.');
      if(bytes.length!=book.size || sha256.convert(bytes).toString()!=book.id) throw const EpubFailure('La copia local está dañada. Reimportar EPUB.');
      return bytes;
    } on EpubFailure { rethrow; } catch (_) { throw const EpubFailure('No se pudo recuperar el EPUB local. Reimportar EPUB.'); }
  }
  Future<ValidatedEpub> open(ImportedEpub book) async {
    final data=await bytes(book); const EpubValidator().validate(data,book.fileName);
    return ValidatedEpub(book,data);
  }
  Future<void> progress(ImportedEpub book) async {
    try { await store.update(owner,book); }
    on EpubFailure { rethrow; } catch (_) { throw const EpubFailure('No se pudo guardar el avance. Revisa el almacenamiento antes de salir.'); }
  }
  Future<void> remove(ImportedEpub book) async {
    try { await store.remove(owner,book.id); }
    catch (_) { throw const EpubFailure('No se pudo completar la eliminación del EPUB. Inténtalo nuevamente.'); }
  }
}
''',
'lib/features/epub/data/epub_file_access.dart':r'''import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/imported_epub.dart';
import 'epub_validator.dart';

abstract interface class EpubFileAccess {
  Future<ValidatedEpub?> pick();
  Future<bool> export(ImportedEpub book,Uint8List bytes);
}
class SystemEpubFileAccess implements EpubFileAccess {
  const SystemEpubFileAccess();
  @override
  Future<ValidatedEpub?> pick() async {
    try {
      final result=await FilePicker.pickFiles(type:FileType.custom,allowedExtensions:['epub'],allowMultiple:false,withData:false,withReadStream:true,cancelUploadOnWindowBlur:false);
      if(result==null) return null;
      if(result.files.length!=1) throw const EpubFailure('Selecciona un único EPUB.');
      final file=result.files.single;
      if(file.size<=0) throw const EpubFailure('El archivo EPUB está vacío.');
      if(file.size>EpubValidator.maxBytes) throw const EpubFailure('El EPUB supera el máximo de 20 MiB.');
      final stream=file.readStream;
      if(stream==null) throw const EpubFailure('No se pudo abrir el archivo seleccionado.');
      final bytes=BytesBuilder(copy:false);
      await for(final chunk in stream) {
        if(bytes.length+chunk.length>EpubValidator.maxBytes) throw const EpubFailure('El EPUB supera el máximo de 20 MiB.');
        bytes.add(chunk);
      }
      if(bytes.length!=file.size) throw const EpubFailure('La lectura del EPUB quedó incompleta. Selecciónalo nuevamente.');
      return const EpubValidator().validate(bytes.takeBytes(),file.name);
    } on EpubFailure { rethrow; } catch (_) { throw const EpubFailure('No se pudo importar el EPUB seleccionado.'); }
    finally { if(!kIsWeb && defaultTargetPlatform==TargetPlatform.android) { try { await FilePicker.clearTemporaryFiles(); } catch (_) {} } }
  }
  @override
  Future<bool> export(ImportedEpub book,Uint8List bytes) async {
    try {
      final name=book.fileName.replaceAll(RegExp(r'[^a-zA-Z0-9áéíóúñÁÉÍÓÚÑ._ -]'),'_');
      final result=await FilePicker.saveFile(dialogTitle:'Exportar copia EPUB',fileName:name, type:FileType.custom,allowedExtensions:['epub'],bytes:bytes);
      return result!=null;
    } catch (_) { throw const EpubFailure('No se pudo exportar la copia EPUB. El libro local permanece guardado.'); }
  }
}
'''
}
for name,text in files.items():
 p=Path(name);p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text,encoding='utf-8')
