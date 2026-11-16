import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/reader_document.dart';
import '../reader_layout.dart';

/// Local, route-scoped reader. No network, account state or library writes.
class TextReaderScreen extends StatefulWidget {
  const TextReaderScreen({super.key, required this.source});
  final ReaderSource source;

  @override
  State<TextReaderScreen> createState() => _TextReaderScreenState();
}

class _TextReaderScreenState extends State<TextReaderScreen> {
  final _scroll = ScrollController(keepScrollOffset: false);
  ReaderDocument? _document;
  ReaderLayout? _layout;
  String? _error;
  int _generation = 0;
  int _layoutGeneration = 0;
  int _position = 0;
  double _fontSize = 18;
  bool _restoring = false;
  bool _scrollPending = false;
  ({double width, double size, double scale, TextDirection direction})? _requested;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant TextReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _document = null;
      _layout = null;
      _requested = null;
      _position = 0;
      _fontSize = 18;
      _error = null;
      _layoutGeneration++;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    try {
      final document = await widget.source.prepare(
        isCancelled: () => !mounted || generation != _generation);
      if (!mounted || generation != _generation) return;
      setState(() => _document = document);
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() => _error = error is ReaderFailure
        ? error.message : 'No pudimos preparar este texto.');
    }
  }

  void _onScroll() {
    if (_restoring || _scrollPending || _layout == null) return;
    _scrollPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollPending = false;
      if (!mounted || _restoring || !_scroll.hasClients || _layout == null) return;
      final next = _layout!.positionAt(math.max(0, _scroll.offset - 20));
      if (next != _position) setState(() => _position = next);
    });
  }

  Future<void> _measure(double width, double scale, TextDirection direction) async {
    final generation = ++_layoutGeneration;
    final document = _document!;
    final anchor = _position;
    setState(() {
      _restoring = true;
      _layout = null;
    });
    try {
      final style = GoogleFonts.merriweather(fontSize: _fontSize, height: 1.8);
      await GoogleFonts.pendingFonts([style]);
      if (!mounted || generation != _layoutGeneration) return;
      final layout = await ReaderLayout.prepare(document, width: width,
        style: style, scaler: TextScaler.linear(scale), direction: direction,
        isCancelled: () => !mounted || generation != _layoutGeneration);
      if (!mounted || generation != _layoutGeneration) return;
      setState(() => _layout = layout);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || generation != _layoutGeneration || !_scroll.hasClients) return;
        _scroll.jumpTo((anchor == 0 ? 0.0 : layout.pixelsFor(anchor) + 20)
          .clamp(0, _scroll.position.maxScrollExtent));
        _restoring = false;
      });
    } catch (error) {
      if (!mounted || generation != _layoutGeneration) return;
      setState(() {
        _restoring = false;
        _error = 'No pudimos organizar el texto para la lectura. Vuelve a intentarlo.';
      });
    }
  }

  void _resize(double delta) {
    setState(() => _fontSize = (_fontSize + delta).clamp(14, 30));
  }

  @override
  void dispose() {
    _generation++;
    _layoutGeneration++;
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.source.title?.trim();
    final author = widget.source.author?.trim();
    final foreground = AppColors.textPrimaryOf(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.deepOf(context),
        foregroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(title?.isNotEmpty == true ? title! : 'Lectura',
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: GoogleFonts.cinzel(color: AppColors.goldOf(context), fontSize: 16)),
      ),
      body: SafeArea(top: false, child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (author?.isNotEmpty == true)
                Text(author!, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: foreground, fontSize: 13)),
              Text('Posición local en el texto', style: TextStyle(
                color: AppColors.textSecondaryOf(context), fontSize: 12)),
            ])),
            IconButton(tooltip: 'Reducir letra',
              onPressed: _fontSize <= 14 ? null : () => _resize(-2),
              icon: const Icon(Icons.text_decrease)),
            Text('${_fontSize.toInt()}', key: const ValueKey('text-reader-font-size'),
              style: TextStyle(color: foreground)),
            IconButton(tooltip: 'Aumentar letra',
              onPressed: _fontSize >= 30 ? null : () => _resize(2),
              icon: const Icon(Icons.text_increase)),
          ]),
        ),
        if (_document != null)
          Semantics(label: 'Posición al inicio de la línea visible, sin guardar en la biblioteca',
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Posición: ${_position + 1} de ${_document!.length}',
                key: const ValueKey('text-reader-position'),
                style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 12)))),
        const SizedBox(height: 8),
        Expanded(child: _error != null
          ? Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.menu_book_outlined, color: AppColors.goldOf(context), size: 32),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center,
                  key: const ValueKey('text-reader-error'),
                  style: GoogleFonts.merriweather(color: foreground, height: 1.6)),
                TextButton(onPressed: () {
                  setState(() {
                    _error = null;
                    _document = null;
                    _layout = null;
                    _requested = null;
                  });
                  unawaited(_load());
                }, child: const Text('Reintentar')),
              ])))
          : _document == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : LayoutBuilder(builder: (context, constraints) {
                final width = math.max(1.0, math.min(720.0, constraints.maxWidth) - 48);
                final scale = MediaQuery.textScalerOf(context).scale(_fontSize) / _fontSize;
                final direction = Directionality.of(context);
                final request = (width: width, size: _fontSize, scale: scale, direction: direction);
                if (_requested != request) {
                  _requested = request;
                  // Invalidate pending work immediately; preparation starts after this build.
                  _layoutGeneration++;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _requested == request && _document != null) {
                      unawaited(_measure(width, scale, direction));
                    }
                  });
                }
                final layout = _layout;
                if (layout == null || layout.width != width ||
                    layout.style.fontSize != _fontSize || layout.scaler.scale(1) != scale ||
                    layout.direction != direction) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                }
                return Center(child: SizedBox(width: width + 48,
                  child: ListView.builder(
                    key: const ValueKey('text-reader-scroll'),
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                    itemCount: _document!.blocks.length,
                    itemExtentBuilder: (index, _) => layout.heights[index],
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_document!.blocks[index].text,
                        key: ValueKey('text-reader-block-$index'),
                        textScaler: layout.scaler, textDirection: layout.direction,
                        style: layout.style.copyWith(color: foreground))),
                  )));
              })),
      ])),
    );
  }
}
