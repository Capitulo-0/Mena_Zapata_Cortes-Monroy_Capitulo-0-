import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/book_status.dart';
import '../../models/library_book.dart';
import '../../models/reading_record.dart';

/// Lectura local de muestra. Abrir la pantalla no modifica el seguimiento.
class SimulatedReaderScreen extends StatefulWidget {
  const SimulatedReaderScreen({
    super.key,
    required this.book,
    required this.initialProgress,
    required this.initialStatus,
    required this.onChanged,
  });
  final LibraryBook book;
  final int initialProgress;
  final BookStatus initialStatus;
  final ValueChanged<ReadingRecord> onChanged;
  @override
  State<SimulatedReaderScreen> createState() => _SimulatedReaderScreenState();
}

class _SimulatedReaderScreenState extends State<SimulatedReaderScreen> {
  final _scroll = ScrollController();
  late int _progress;
  bool _restoring = true;
  bool get _completed => widget.initialStatus == BookStatus.leido;

  @override
  void initState() {
    super.initState();
    _progress = widget.initialProgress.clamp(0, 100);
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      // Los libros leídos se abren desde el inicio para consultarlos, sin reiniciarlos.
      if (!_completed) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent * _progress / 100);
      }
      _restoring = false;
    });
  }

  void _onScroll() {
    if (_restoring || _completed || !_scroll.hasClients) return;
    final extent = _scroll.position.maxScrollExtent;
    if (extent <= 0) return;
    final next = math.max(
      _progress,
      (_scroll.offset.clamp(0, extent) * 100 / extent).floor(),
    );
    if (next == _progress) return;
    setState(() => _progress = next);
    widget.onChanged(
      ReadingRecord(
        format: 'Lector simulado',
        currentPage: (next * 4 / 100).ceil().clamp(0, 4),
        totalPages: 4,
        publisher: widget.book.publisher,
        readerProgress: next,
        status: next == 100 ? BookStatus.leido : BookStatus.leyendo,
      ),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final secondary = AppColors.textSecondaryOf(context);
    final paragraphs = <String>[
      widget.book.synopsis,
      'La mañana había llegado despacio. Al otro lado de la ventana, la ciudad empezaba a despertar y el sonido de los primeros pasos se mezclaba con el viento entre los árboles. Sobre la mesa descansaba un libro abierto, esperando a quien quisiera escuchar su historia.',
      'Ella se detuvo antes de cruzar el umbral. Había imaginado aquel lugar muchas veces, pero ninguna de sus ideas se parecía del todo a lo que veía. Las paredes guardaban recuerdos y la luz dibujaba caminos sobre el suelo. Decidió entrar sin prisa.',
      'Entre los estantes encontró una carta sin destinatario. No contenía grandes secretos, solo una invitación a mirar con más atención las cosas pequeñas: una conversación pendiente, una taza compartida, una puerta que todavía podía abrirse.',
      'Afuera continuaba la vida de siempre. Alguien regresaba a casa, alguien se despedía en una esquina y alguien descubría que aún tenía tiempo para cambiar de rumbo. Todas aquellas historias avanzaban juntas sin saberlo.',
      'Volvió a sentarse junto a la ventana. La lectura tenía esa forma tranquila de acompañar: no pedía respuestas inmediatas ni prometía resolverlo todo. Bastaba seguir una línea y después otra, dejando que las palabras encontraran su lugar.',
      'Cuando levantó la vista, el paisaje parecía distinto. Los árboles seguían allí y las calles conservaban sus nombres, pero ahora notaba detalles que antes habían pasado inadvertidos. Sonrió y regresó al libro.',
      'Fin de la muestra. Este contenido fue creado únicamente para demostrar la experiencia de lectura de Capítulo 0; no es el texto original ni la edición completa de esta obra.',
    ];
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.backgroundOf(context),
        foregroundColor: AppColors.textPrimaryOf(context),
        elevation: 0,
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              widget.book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: secondary),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Muestra de demostración',
                    style: TextStyle(fontSize: 12, color: secondary),
                  ),
                ),
                Text(
                  _completed ? 'Leído · $_progress%' : '$_progress%',
                  key: const ValueKey('reader-progress'),
                  style: TextStyle(fontSize: 12, color: secondary),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: _progress / 100,
            minHeight: 2,
            color: AppColors.goldOf(context),
            backgroundColor: AppColors.surfaceSoftOf(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              key: const ValueKey('reader-scroll'),
              controller: _scroll,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 40, 28, 64),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.book.title,
                          style: TextStyle(
                            fontSize: 24,
                            height: 1.4,
                            fontFamily: 'Merriweather_regular',
                            color: AppColors.textPrimaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 28),
                        for (final paragraph in paragraphs)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Text(
                              paragraph,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontFamily: 'Merriweather_regular',
                                    fontSize: 17,
                                    height: 1.85,
                                    color: AppColors.textPrimaryOf(context),
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
