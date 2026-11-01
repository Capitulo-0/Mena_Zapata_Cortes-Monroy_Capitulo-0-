import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/book_review.dart';

class LibraryReviewDialog extends StatefulWidget {
  const LibraryReviewDialog({
    super.key,
    required this.initial,
    required this.bookTitle,
    required this.onSave,
  });

  final BookReview? initial;
  final String bookTitle;
  final ValueChanged<BookReview> onSave;

  @override
  State<LibraryReviewDialog> createState() => _LibraryReviewDialogState();
}

class _LibraryReviewDialogState extends State<LibraryReviewDialog> {
  late int _rating;
  late bool _isPublic;
  late TextEditingController _controller;

  bool get _isEditing => widget.initial != null;

  Color get _background => AppColors.backgroundOf(context);
  Color get _surface => AppColors.surfaceOf(context);
  Color get _textPrimary => AppColors.textPrimaryOf(context);
  Color get _textSecondary => AppColors.textSecondaryOf(context);
  Color get _gold => AppColors.goldOf(context);
  Color get _accent => AppColors.accentOf(context);
  Color get _deep => AppColors.deepOf(context);

  @override
  void initState() {
    super.initState();
    _rating = widget.initial?.rating ?? 5;
    _isPublic = widget.initial?.isPublic ?? true;
    _controller =
        TextEditingController(text: widget.initial?.text ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _rating > 0 && _controller.text.trim().isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _gold.withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.11),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _gold.withValues(alpha: 0.26),
                      ),
                    ),
                    child: Icon(
                      _isEditing
                          ? Icons.rate_review_outlined
                          : Icons.star_outline_rounded,
                      color: _gold,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing
                              ? 'EDITAR RESEÑA'
                              : 'CALIFICAR Y RESEÑAR',
                          style: GoogleFonts.cinzel(
                            color: _accent,
                            fontSize: 7.4,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.65,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.bookTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.merriweather(
                            color: _textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _gold.withValues(alpha: 0.34),
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: _textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                'TU CALIFICACIÓN',
                style: GoogleFonts.cinzel(
                  color: _textPrimary,
                  fontSize: 7.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: List.generate(5, (index) {
                  final value = index + 1;
                  final selected = value <= _rating;

                  return Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: InkWell(
                      onTap: () => setState(() => _rating = value),
                      customBorder: const CircleBorder(),
                      child: Icon(
                        selected
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: _gold,
                        size: 24,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                minLines: 4,
                maxLines: 6,
                maxLength: 500,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.merriweather(
                  color: _textPrimary,
                  fontSize: 8.2,
                  height: 1.45,
                ),
                decoration: InputDecoration(
                  hintText: '¿Qué te pareció esta lectura?',
                  counterText: '',
                  filled: true,
                  fillColor: _background,
                  hintStyle: GoogleFonts.merriweather(
                    color: _textSecondary,
                    fontSize: 8,
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(
                    11,
                    10,
                    11,
                    10,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide(
                      color: _gold.withValues(alpha: 0.34),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide(color: _gold),
                  ),
                ),
              ),
              const SizedBox(height: 11),
              Text(
                'PRIVACIDAD DE LA RESEÑA',
                style: GoogleFonts.cinzel(
                  color: _textPrimary,
                  fontSize: 7.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                height: 34,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _privacyButton(
                        label: '🌐  Pública',
                        selected: _isPublic,
                        onTap: () =>
                            setState(() => _isPublic = true),
                      ),
                    ),
                    Expanded(
                      child: _privacyButton(
                        label: '🔒  Privada',
                        selected: !_isPublic,
                        onTap: () =>
                            setState(() => _isPublic = false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isPublic
                    ? 'Visible para todos los lectores y en Mis reseñas.'
                    : 'Se mostrará como anónima para la comunidad.',
                style: GoogleFonts.inter(
                  color: _textSecondary,
                  fontSize: 6.7,
                ),
              ),
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_controller.text.length} / 500',
                  style: GoogleFonts.inter(
                    color: _textSecondary,
                    fontSize: 6.2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textPrimary,
                          side: BorderSide(
                            color: _gold.withValues(alpha: 0.34),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.inter(
                            fontSize: 7.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 38,
                      child: FilledButton(
                        onPressed: canSave
                            ? () {
                                final review = BookReview(
                                  rating: _rating,
                                  text: _controller.text.trim(),
                                  isPublic: _isPublic,
                                );

                                widget.onSave(review);
                                Navigator.of(context).pop();
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          disabledBackgroundColor:
                              _accent.withValues(alpha: 0.30),
                          foregroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        child: Text(
                          _isEditing
                              ? 'Guardar cambios'
                              : 'Publicar reseña',
                          style: GoogleFonts.inter(
                            fontSize: 7.4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _privacyButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _deep : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected
                ? AppColors.background
                : _textPrimary,
            fontSize: 6.8,
            fontWeight: selected
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
