import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

import '../../../core/session/local_account_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../data/epub_repository.dart';
import '../data/epub_viewport.dart';
import '../models/imported_epub.dart';

class EpubReaderScreen extends StatefulWidget {
  const EpubReaderScreen({
    super.key,
    required this.source,
    required this.repository,
    required this.account,
  });
  final ValidatedEpub source;
  final EpubRepository repository;
  final String account;
  @override
  State<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen> {
  final _controller = EpubController();
  late ImportedEpub _book;
  late EpubSource _source;
  late bool _restoring;
  bool _ready = false,
      _showIndex = false,
      _locationsReady = false,
      _closing = false,
      _allowPop = false;
  String? _error, _saveError;
  Future<void> _saves = Future.value();
  bool get _active =>
      mounted && (LocalAccountScope.read(context) ?? 'guest') == widget.account;
  @override
  void initState() {
    super.initState();
    _book = widget.source.book;
    _source = EpubSource.fromData(widget.source.bytes);
    _restoring = _book.cfi.isNotEmpty;
  }

  void _save() {
    final book = _book;
    _saves = _saves.then((_) async {
      if (!_active) return;
      try {
        await widget.repository.progress(book);
        if (_active) setState(() => _saveError = null);
      } catch (_) {
        if (_active) {
          setState(
            () => _saveError = 'No se guardó el avance. Revisa espacio y permisos antes de salir.',
          );
        }
      }
    });
  }

  void _position(EpubLocation value) {
    if (!_active || _restoring || value.startCfi.isEmpty) return;
    setState(
      () => _book = _book.position(
        cfi: value.startCfi,
        progress: _locationsReady && value.progress.isFinite
            ? value.progress.clamp(0, 1)
            : _book.progress,
      ),
    );
    _save();
  }

  Future<void> _font(int delta) async {
    if (!_ready || !_active) return;
    final size = (_book.fontSize + delta).clamp(12, 32);
    try {
      await _controller.setFontSize(fontSize: size.toDouble());
      if (!_active) return;
      setState(() => _book = _book.position(fontSize: size));
      _save();
    } catch (_) {
      if (_active) {
        setState(
          () => _error = 'No se pudo ajustar la letra. Vuelve a abrir el EPUB.',
        );
      }
    }
  }

  Future<void> _leave({bool discard = false}) async {
    if (_closing) return;
    _closing = true;
    if (_active && !discard) {
      await _saves;
      if (!_active) {
        _pop();
        return;
      }
      try {
        await widget.repository.progress(_book);
      } catch (_) {
        if (mounted) {
          setState(
            () => _saveError = 'No se guardó el avance. Puedes reintentar o salir sin guardar.',
          );
        }
        _closing = false;
        return;
      }
    }
    _pop();
  }

  void _pop() {
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final account =
        context.dependOnInheritedWidgetOfExactType<LocalAccountScope>()?.uid ??
        'guest';
    if (account != widget.account) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lectura cerrada')),
        body: const Center(
          child: Text('La cuenta cambió. Vuelve a Mi Biblioteca.'),
        ),
      );
    }
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundOf(context),
        appBar: AppBar(
          backgroundColor: AppColors.deep,
          foregroundColor: AppColors.background,
          leading: IconButton(
            tooltip: 'Volver a Mi Biblioteca',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _leave(),
          ),
          title: Text(
            _book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _book.author,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '${(_book.progress * 100).round()} %',
                      key: const ValueKey('epub-progress'),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    key: const ValueKey('epub-index'),
                    tooltip: 'Índice de capítulos',
                    onPressed: () => setState(() => _showIndex = !_showIndex),
                    icon: const Icon(Icons.list),
                  ),
                  IconButton(
                    tooltip: 'Página anterior',
                    onPressed: _ready ? () => _controller.prev() : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    tooltip: 'Reducir letra EPUB',
                    onPressed: _ready && _book.fontSize > 12
                        ? () => _font(-2)
                        : null,
                    icon: const Icon(Icons.text_decrease),
                  ),
                  Text(
                    '${_book.fontSize}',
                    key: const ValueKey('epub-font-size'),
                  ),
                  IconButton(
                    tooltip: 'Aumentar letra EPUB',
                    onPressed: _ready && _book.fontSize < 32
                        ? () => _font(2)
                        : null,
                    icon: const Icon(Icons.text_increase),
                  ),
                  IconButton(
                    tooltip: 'Página siguiente',
                    onPressed: _ready ? () => _controller.next() : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              if (_saveError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Text(
                        _saveError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      TextButton(
                        onPressed: () => _leave(discard: true),
                        child: const Text('Salir sin guardar'),
                      ),
                    ],
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!),
                ),
              if (!_ready && _error == null) const LinearProgressIndicator(),
              if (_showIndex)
                SizedBox(
                  height: 150,
                  child: ListView(
                    children: [
                      for (final chapter in _book.chapters)
                        ListTile(
                          dense: true,
                          title: Text(chapter.title),
                          onTap: _ready
                              ? () {
                                  setState(() => _showIndex = false);
                                  // epub.js restores its old CFI while resizing: navigate after that restoration.
                                  Future<void>.delayed(
                                    const Duration(milliseconds: 350),
                                    () {
                                      if (_active && _ready) {
                                        _controller.display(cfi: chapter.href);
                                      }
                                    },
                                  );
                                }
                              : null,
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: _error != null
                    ? const Center(
                        child: Text(
                          'No se pudo abrir el EPUB. Regresa y reimpórtalo si es necesario.',
                        ),
                      )
                    : EpubViewer(
                        key: ValueKey(_book.id),
                        epubSource: _source,
                        epubController: _controller,
                        initialCfi: _book.cfi.isEmpty
                            ? null
                            : widget.source.book.cfi,
                        useLocalServer: false,
                        displaySettings: EpubDisplaySettings(
                          fontSize: _book.fontSize,
                          spread: EpubSpread.none,
                          flow: EpubFlow.paginated,
                          allowScriptedContent: false,
                          useSnapAnimationAndroid: false,
                          theme: EpubTheme.custom(
                            backgroundDecoration: const BoxDecoration(
                              color: Color(0xFFF6EFDF),
                            ),
                            foregroundColor: const Color(0xFF3B2A20),
                            customCss: {
                              'body': {
                                'font-family': 'Georgia, serif',
                                'line-height': '1.6',
                                'background-color': '#F6EFDF',
                                'color': '#3B2A20',
                              },
                            },
                          ),
                        ),
                        onEpubLoaded: () {
                          if (!_active || _ready) return;
                          setState(() => _ready = true);
                          fitEpubViewport();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_active) {
                              _controller.display(
                                cfi: widget.source.book.cfi.isNotEmpty
                                    ? widget.source.book.cfi
                                    : _book.chapters.first.href,
                              );
                            }
                          });
                        },
                        onLoadError: (_) {
                          if (_active) {
                            setState(
                              () => _error = 'Este EPUB no se pudo mostrar. No se ha modificado el archivo original.',
                            );
                          }
                        },
                        onInitialPositionLoading: (_) {
                          _restoring = true;
                        },
                        onInitialPositionLoaded: () {
                          _restoring = false;
                        },
                        onLocationLoaded: () async {
                          _locationsReady = true;
                          try {
                            final position = await _controller
                                .getCurrentLocation();
                            if (_active) _position(position);
                          } catch (_) {}
                        },
                        onRelocated: _position,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
