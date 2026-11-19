import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/widgets/home_network_cover.dart';
import '../../services/literary_chat.dart';

class LiteraryChatScreen extends StatefulWidget {
  const LiteraryChatScreen({
    super.key,
    required this.repository,
    this.editor = ChatEditor.none,
    this.excerpt = '',
    this.genre = '',
    this.title = '',
    this.onBook,
  });

  final LiteraryChatRepository repository;
  final ChatEditor editor;
  final String excerpt;
  final String genre;
  final String title;
  final Future<void> Function(Map<String, dynamic>)? onBook;

  static Future<ChatSection?> open(
    BuildContext context,
    LiteraryChatScreen screen,
  ) {
    return Navigator.of(context, rootNavigator: true).push<ChatSection>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => screen),
    );
  }

  @override
  State<LiteraryChatScreen> createState() => _LiteraryChatScreenState();
}

class _LiteraryChatScreenState extends State<LiteraryChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <({String text, ChatReply? reply})>[];
  late final StreamSubscription<bool> _identity;
  ChatChoice? _story;
  ChatChoice? _chapter;
  bool _shareEditor = false;
  bool _useLibrary = false;
  bool _busy = false;
  bool _active = true;
  int _version = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _active = widget.repository.chatAccountIsCurrent;
    _identity = widget.repository.chatAccountActive.listen((active) {
      if (!active && mounted && _active) {
        setState(() {
          _active = false;
          _clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _identity.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _clear() {
    _version++;
    _messages.clear();
    _input.clear();
    _error = null;
    _busy = false;
    _story = null;
    _chapter = null;
    _shareEditor = false;
    _useLibrary = false;
  }

  void _bottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      } else {
        unawaited(
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          ),
        );
      }
    });
  }

  List<ChatTurn> get _history {
    final turns = <ChatTurn>[];
    String clip(String text) {
      if (text.length <= 1200) return text;
      final end =
          text.codeUnitAt(1199) >= 0xD800 && text.codeUnitAt(1199) <= 0xDBFF
          ? 1199
          : 1200;
      return text.substring(0, end);
    }

    for (final message in _messages) {
      if (message.reply case final reply?) {
        turns.add((role: 'user', text: clip(message.text)));
        final text = reply.sections
            .map((part) => '${part.heading}\n${part.text}')
            .join('\n\n');
        final books = reply.books.map((book) => book['title']).join(', ');
        turns.add((
          role: 'assistant',
          text: clip(books.isEmpty ? text : '$text\n$books'),
        ));
      }
    }
    return turns.length <= 6 ? turns : turns.sublist(turns.length - 6);
  }

  Future<void> _send({bool retry = false}) async {
    if (_busy || !_active) return;
    final text = retry ? _messages.last.text : _input.text.trim();
    if (text.isEmpty) return;
    final history = _history;
    final version = ++_version;
    setState(() {
      if (!retry && _messages.isNotEmpty && _messages.last.reply == null) {
        _messages.removeLast();
      }
      if (!retry) _messages.add((text: text, reply: null));
      _input.clear();
      _busy = true;
      _error = null;
    });
    _bottom();
    try {
      final reply = await widget.repository
          .chat(
            message: text,
            history: history,
            storyId: _story?.id,
            chapterId: _chapter?.id,
            useLibrary: _useLibrary,
            excerpt: _shareEditor ? widget.excerpt : '',
            genre: _shareEditor ? widget.genre : '',
          )
          .timeout(const Duration(seconds: 55));
      if (!mounted || version != _version) return;
      setState(
        () => _messages[_messages.length - 1] = (text: text, reply: reply),
      );
    } on ApiFailure catch (error) {
      if (mounted && version == _version) {
        setState(() => _error = error.message);
      }
    } on TimeoutException {
      if (mounted && version == _version) {
        setState(() => _error = 'La solicitud tardó demasiado.');
      }
    } catch (_) {
      if (mounted && version == _version) {
        setState(() => _error = 'No pudimos obtener una respuesta.');
      }
    } finally {
      if (mounted && version == _version) {
        setState(() => _busy = false);
        if (_error != null) _bottom();
      }
    }
  }

  Future<ChatChoice?> _choose({String? storyId}) async {
    try {
      final choices = widget.repository.chatStories(storyId: storyId);
      return await showModalBottomSheet<ChatChoice>(
        context: context,
        useSafeArea: true,
        builder: (context) => FutureBuilder<List<ChatChoice>>(
          future: choices,
          builder: (context, data) {
            if (data.hasError) {
              return const Center(child: Text('No pudimos cargar la lista.'));
            }
            if (!data.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (data.data!.isEmpty) {
              return Center(
                child: Text(
                  storyId == null
                      ? 'Aún no tienes historias.'
                      : 'Esta historia no tiene capítulos.',
                ),
              );
            }
            return ListView(
              children: [
                ListTile(
                  title: Text(
                    storyId == null
                        ? 'Mis historias'
                        : 'Capítulos de la historia',
                  ),
                ),
                for (final choice in data.data!)
                  ListTile(
                    title: Text(choice.title),
                    onTap: () => Navigator.pop(context, choice),
                  ),
              ],
            );
          },
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _select({bool chapter = false}) async {
    final version = _version;
    final choice = await _choose(storyId: chapter ? _story?.id : null);
    if (!mounted || choice == null || !_active || version != _version) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(choice.title),
        content: Text(
          chapter
              ? 'Autoriza compartir con Google Gemini el título y hasta 3000 caracteres finales de este capítulo.'
              : 'Autoriza compartir con Google Gemini el título, género y hasta 1200 caracteres de la sinopsis de esta historia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Autorizar'),
          ),
        ],
      ),
    );
    if (!mounted || approved != true || !_active || version != _version) return;
    setState(() {
      _messages.clear();
      _error = null;
      if (chapter) {
        _chapter = choice;
      } else {
        _story = choice;
        _chapter = null;
        _shareEditor = false;
      }
    });
  }

  bool _canApply(ChatSection part) =>
      _story == null &&
      switch (widget.editor) {
        ChatEditor.story => part.action == 'TITLE' || part.action == 'SYNOPSIS',
        ChatEditor.chapter => part.action == 'INSERT',
        ChatEditor.none => false,
      };

  Future<void> _apply(ChatSection part) async {
    if (!_active || _busy) return;
    final original = part.action == 'TITLE' ? widget.title : widget.excerpt;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(
          part.action == 'INSERT' ? 'Insertar al final' : 'Aplicar al borrador',
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (part.action != 'INSERT' && original.isNotEmpty) ...[
              const Text('Texto actual'),
              Text(original),
              const SizedBox(height: 12),
            ],
            const Text('Sugerencia'),
            SelectableText(part.text),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
    if (mounted &&
        _active &&
        widget.repository.chatAccountIsCurrent &&
        ok == true) {
      Navigator.pop(context, part);
    }
  }

  Widget _bubble(
    BuildContext context, {
    required bool mine,
    required Widget child,
  }) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 590),
        margin: EdgeInsets.only(
          left: mine ? 28 : 0,
          right: mine ? 0 : 18,
          bottom: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: mine ? AppColors.deep : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.gold.withValues(alpha: .32)),
        ),
        child: DefaultTextStyle.merge(
          style: GoogleFonts.merriweather(
            fontSize: 13,
            height: 1.55,
            color: mine
                ? AppColors.background
                : AppColors.textPrimaryOf(context),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _reply(BuildContext context, ChatReply reply, int index) => _bubble(
    context,
    mine: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final part in reply.sections)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoftOf(context).withValues(alpha: .40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (part.heading.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      part.heading,
                      style: GoogleFonts.cinzel(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                SelectableText(part.text),
                Wrap(
                  children: [
                    TextButton(
                      onPressed: () =>
                          Clipboard.setData(ClipboardData(text: part.text)),
                      child: const Text('Copiar'),
                    ),
                    if (_canApply(part))
                      TextButton(
                        onPressed: _busy ? null : () => _apply(part),
                        child: Text(switch (part.action) {
                          'TITLE' => 'Usar título',
                          'SYNOPSIS' => 'Comparar sinopsis',
                          _ => 'Insertar',
                        }),
                      ),
                  ],
                ),
              ],
            ),
          ),
        for (final book in reply.books)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              type: MaterialType.transparency,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: HomeNetworkCover(
                  url: book['coverUrl'] as String? ?? '',
                  width: 34,
                  height: 48,
                  title: book['title'] as String,
                ),
                title: Text(book['title'] as String),
                subtitle: Text((book['authors'] as List? ?? []).join(', ')),
                onTap: widget.onBook == null
                    ? null
                    : () => widget.onBook!({
                        'googleVolumeId': book['volumeId'],
                        'title': book['title'],
                        'author': (book['authors'] as List? ?? []).join(', '),
                      }),
              ),
            ),
          ),
        TextButton(
          onPressed: _busy
              ? null
              : () => setState(() => _messages.removeAt(index)),
          child: const Text('Descartar'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.deep,
        foregroundColor: AppColors.background,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asistente Capítulo 0',
              style: GoogleFonts.cinzel(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Tu compañero de lectura y escritura.',
              style: GoogleFonts.merriweather(fontSize: 9),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Nueva conversación',
            onPressed: _active ? () => setState(_clear) : null,
            icon: const Icon(Icons.add_comment_outlined, color: AppColors.gold),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 4),
                    children: [
                      if (_messages.isEmpty)
                        _bubble(
                          context,
                          mine: false,
                          child: Text(
                            _active
                                ? '¿Qué te gustaría leer o escribir hoy? Tus mensajes se envían a Google Gemini.'
                                : 'Esta conversación se cerró al cambiar de cuenta.',
                          ),
                        ),
                      for (
                        var index = 0;
                        index < _messages.length;
                        index++
                      ) ...[
                        _bubble(
                          context,
                          mine: true,
                          child: Text(_messages[index].text),
                        ),
                        if (_messages[index].reply case final reply?)
                          _reply(context, reply, index),
                      ],
                      if (_busy)
                        _bubble(
                          context,
                          mine: false,
                          child: const _WritingDots(),
                        ),
                      if (_error case final error?)
                        _bubble(
                          context,
                          mine: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(error),
                              TextButton(
                                onPressed: () => _send(retry: true),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (_active)
                  Material(
                    color: AppColors.surfaceOf(context),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 44,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                ActionChip(
                                  label: Text(
                                    _story == null
                                        ? 'Mi historia'
                                        : 'Historia: ${_story!.title}',
                                  ),
                                  onPressed: _busy ? null : () => _select(),
                                ),
                                if (_story != null) ...[
                                  const SizedBox(width: 6),
                                  ActionChip(
                                    label: Text(
                                      _chapter == null
                                          ? 'Capítulo'
                                          : 'Capítulo: ${_chapter!.title}',
                                    ),
                                    onPressed: _busy
                                        ? null
                                        : () => _select(chapter: true),
                                  ),
                                  IconButton(
                                    tooltip: 'Quitar historia',
                                    onPressed: _busy
                                        ? null
                                        : () => setState(_clear),
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                                if (_story == null &&
                                    (widget.excerpt.isNotEmpty ||
                                        widget.genre.isNotEmpty)) ...[
                                  const SizedBox(width: 6),
                                  FilterChip(
                                    label: const Text(
                                      'Compartir fragmento del editor',
                                    ),
                                    selected: _shareEditor,
                                    onSelected: _busy
                                        ? null
                                        : (value) async {
                                            final allowed =
                                                !value ||
                                                await showDialog<bool>(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: const Text(
                                                          'Compartir con Gemini',
                                                        ),
                                                        scrollable: true,
                                                        content: Text(
                                                          'Se enviarán el género y este fragmento:\n\n${widget.excerpt}',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  context,
                                                                ),
                                                            child: const Text(
                                                              'Cancelar',
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  context,
                                                                  true,
                                                                ),
                                                            child: const Text(
                                                              'Autorizar',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ) ==
                                                    true;
                                            if (mounted && _active && allowed) {
                                              setState(() {
                                                if (!value) {
                                                  _messages.clear();
                                                  _error = null;
                                                }
                                                _shareEditor = value;
                                              });
                                            }
                                          },
                                  ),
                                ],
                                const SizedBox(width: 6),
                                FilterChip(
                                  label: const Text('Usar mi biblioteca'),
                                  selected: _useLibrary,
                                  tooltip: 'Usar preferencias para buscar libros. Tu biblioteca no se envía a Gemini.',
                                  onSelected: _busy
                                      ? null
                                      : (value) =>
                                            setState(() => _useLibrary = value),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: TextField(
                                  key: const ValueKey('literary-chat-input'),
                                  controller: _input,
                                  maxLength: 2000,
                                  minLines: 1,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    hintText: 'Escribe un mensaje…',
                                    counterText: '',
                                  ),
                                ),
                              ),
                              IconButton.filled(
                                tooltip: 'Enviar',
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _busy ? null : _send,
                                icon: const Icon(Icons.send_rounded),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WritingDots extends StatefulWidget {
  const _WritingDots();
  @override
  State<_WritingDots> createState() => _WritingDotsState();
}

class _WritingDotsState extends State<_WritingDots>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.stop();
    } else {
      _animation.repeat();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Gemini está escribiendo',
    liveRegion: true,
    child: AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          final wave = MediaQuery.disableAnimationsOf(context)
              ? 1.0
              : (math.cos(2 * math.pi * (_animation.value - index / 5)) + 1) /
                    2;
          return Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: .35 + .65 * wave),
            ),
          );
        }),
      ),
    ),
  );
}
