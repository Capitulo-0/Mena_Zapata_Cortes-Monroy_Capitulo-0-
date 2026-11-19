import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../services/chat_dictation.dart';

class ChatMicrophone extends StatefulWidget {
  const ChatMicrophone({
    super.key,
    required this.dictation,
    required this.enabled,
    required this.onText,
  });

  final ChatDictation dictation;
  final bool enabled;
  final ValueChanged<String> onText;

  @override
  State<ChatMicrophone> createState() => _ChatMicrophoneState();
}

class _ChatMicrophoneState extends State<ChatMicrophone>
    with WidgetsBindingObserver {
  bool _listening = false;
  bool _starting = false;
  bool _stopping = false;
  int _session = 0;
  Timer? _deadline;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(ChatMicrophone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && oldWidget.enabled) _cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deadline?.cancel();
    if (_listening || _starting) unawaited(_release());
    super.dispose();
  }

  Future<void> _release() async {
    try {
      await widget.dictation.cancel();
    } catch (_) {
      // Closing the editor must also work when the recognition service stops.
    }
  }

  void _cancel() {
    if (!_listening && !_starting) return;
    _finish();
    unawaited(_release());
  }

  void _finish([String? error]) {
    _deadline?.cancel();
    _session++;
    if (!mounted) return;
    setState(() {
      _listening = false;
      _starting = false;
      _stopping = false;
    });
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _begin() async {
    setState(() => _starting = true);
    final session = ++_session;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dictar mensaje'),
        content: const Text(
          'Tu navegador o dispositivo procesa la voz y puede usar su servicio en línea. '
          'Capítulo 0 no guarda audio. Podrás editar el texto antes de enviarlo a Gemini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Permitir dictado'),
          ),
        ],
      ),
    );
    if (!mounted || session != _session) return;
    if (accepted != true || !widget.enabled) {
      _finish();
      return;
    }
    setState(() {
      _starting = false;
      _listening = true;
    });
    _deadline = Timer(const Duration(seconds: 35), _cancel);
    await widget.dictation.start(
      onText: (text) {
        if (mounted &&
            session == _session &&
            widget.enabled &&
            text.trim().isNotEmpty) {
          widget.onText(text.trim());
        }
      },
      onDone: () {
        if (mounted && session == _session) _finish();
      },
      onError: (message) {
        if (mounted && session == _session) {
          _finish(message);
          unawaited(_release());
        }
      },
    );
  }

  Future<void> _stop() async {
    setState(() => _stopping = true);
    try {
      await widget.dictation.stop();
    } catch (_) {
      if (mounted && _listening) {
        _finish('No se pudo finalizar el dictado. Puedes escribir tu mensaje.');
        unawaited(_release());
      }
    }
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: _stopping
            ? 'Procesando dictado'
            : _listening
            ? 'Detener dictado'
            : 'Dictar en español',
        onPressed: !widget.enabled || _starting || _stopping
            ? null
            : _listening
            ? _stop
            : _begin,
        color: _listening ? AppColors.gold : AppColors.accent,
        icon: Icon(
          _listening ? Icons.stop_circle_outlined : Icons.mic_none_rounded,
        ),
      ),
      if (_listening)
        IconButton(
          tooltip: 'Cancelar dictado',
          onPressed: _cancel,
          icon: const Icon(Icons.close_rounded),
        ),
    ],
  );
}
