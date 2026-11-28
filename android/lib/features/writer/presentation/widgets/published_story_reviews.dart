part of '../screens/published_story_screen.dart';

extension _PublishedStoryReviews on _PublishedStoryScreenState {
  Widget _buildReviewSection() {
    final reviews = _reviews;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (reviews?.busy == true) LinearProgressIndicator(color: _accent, backgroundColor: _gold.withValues(alpha: 0.16), minHeight: 2),
        if (reviews != null && reviews.error != null) ...[
          Text(reviews.error!, style: GoogleFonts.inter(color: _textSecondary, fontSize: 8)),
          TextButton(onPressed: reviews.busy ? null : () => unawaited(reviews.refresh()), child: Text('Recargar reseñas', style: GoogleFonts.inter(color: _accent, fontSize: 7))),
        ],
        AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: _reviewEditorOpen
          ? _buildReviewEditor()
          : _hasReview
          ? _buildPublishedReview()
          : _buildReviewCallToAction(),
        ),
        if (_hasReview && !_reviewEditorOpen)
          TextButton(onPressed: reviews?.busy == true ? null : _deleteReview, child: Text('Eliminar mi reseña', style: GoogleFonts.inter(color: _accent, fontSize: 7))),
        for (final review in reviews?.reviews ?? const <SocialReview>[])
          if (!review.ownReview && review.visibility != ReviewVisibility.private) _buildCommunityReview(review),
      ],
    );
  }

  Widget _buildReviewCallToAction() {
    return SizedBox(
      width: double.infinity,
      height: 38,
      child: OutlinedButton(
        onPressed: _reviews?.busy == true || (_reviews == null && !widget.isGuest) ? null : _openReviewEditor,
        style: OutlinedButton.styleFrom(
          foregroundColor: _textPrimary,
          side: BorderSide(color: _gold.withValues(alpha: 0.40)),
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        child: Text(
          '★ Calificar y reseñar',
          style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildReviewEditor() {
    final canPublish =
        _draftRating > 0 && _reviews?.busy == false && _reviews?.loaded == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gold.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TU CALIFICACIÓN',
            style: GoogleFonts.cinzel(
              color: _textPrimary,
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: List.generate(5, (index) {
              final value = index + 1;
              final selected = value <= _draftRating;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    _updateState(() {
                      _draftRating = value;
                    });
                  },
                  customBorder: const CircleBorder(),
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('review-star-$value-$_draftRating'),
                    tween: Tween<double>(begin: 0.72, end: 1),
                    duration: const Duration(milliseconds: 190),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Icon(
                      selected ? Icons.star_rounded : Icons.star_border_rounded,
                      color: _gold,
                      size: 23,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reviewController,
            minLines: 4,
            maxLines: 6,
            maxLength: 500,
            onChanged: (_) {
              _updateState(() {});
            },
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
              contentPadding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: BorderSide(color: _gold.withValues(alpha: 0.34)),
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
              border: Border.all(color: _gold.withValues(alpha: 0.28)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _reviewPrivacyButton(
                    label: '🌐  Pública',
                    selected: _draftReviewIsPublic,
                    onTap: () {
                      _updateState(() {
                        _draftReviewIsPublic = true;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _reviewPrivacyButton(
                    label: _reviews?.ownReview?.visibility == ReviewVisibility.private ? '🔒  Solo yo' : '🔒  Privada',
                    selected: !_draftReviewIsPublic,
                    onTap: () {
                      _updateState(() {
                        _draftReviewIsPublic = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              _draftReviewIsPublic
                  ? 'Visible para todos los lectores.'
                  : (_reviews?.ownReview?.visibility == ReviewVisibility.private ? 'Visible solo para ti.' : 'Anonimo para todos los lectores.'),
              key: ValueKey(_draftReviewIsPublic),
              style: GoogleFonts.inter(color: _textSecondary, fontSize: 6.7),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_reviewController.text.length} / 500',
              style: GoogleFonts.inter(color: _textSecondary, fontSize: 6.2),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: _reviews?.busy == true ? null : _cancelReviewEditing,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textPrimary,
                      side: BorderSide(color: _gold.withValues(alpha: 0.34)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.inter(
                        fontSize: 7.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 36,
                  child: FilledButton(
                    onPressed: canPublish ? _publishReview : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      disabledBackgroundColor: _accent.withValues(alpha: 0.32),
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: Text(
                      _hasReview ? 'Guardar cambios' : 'Publicar reseña',
                      style: GoogleFonts.inter(
                        fontSize: 7.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reviewPrivacyButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.deepOf(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? AppColors.background : _textPrimary,
            fontSize: 6.8,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPublishedReview() {
    final displayedUser = _reviewIsPublic ? widget.currentUsername : '@anonimo';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _gold.withValues(alpha: 0.23)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: InkWell(
                  onTap: null,
                  borderRadius: BorderRadius.circular(5),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      displayedUser,
                      style: GoogleFonts.inter(
                        color: _accent,
                        fontSize: 6.8,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.none,
                        decorationColor: _accent,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: _gold.withValues(alpha: 0.28)),
                ),
                child: Text(
                  _reviewIsPublic ? '🌐 Pública' : (_reviews?.ownReview?.visibility == ReviewVisibility.private ? '🔒 Solo yo' : '🔒 Privada'),
                  style: GoogleFonts.inter(
                    color: _textSecondary,
                    fontSize: 6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              InkWell(
                onTap: _openReviewEditor,
                child: Text(
                  'Editar reseña',
                  style: GoogleFonts.inter(
                    color: _accent,
                    fontSize: 6.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < _rating
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: _gold,
                size: 13,
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _reviewText,
            style: GoogleFonts.merriweather(
              color: _textPrimary,
              fontSize: 7.7,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityReview(SocialReview review) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _gold.withValues(alpha: 0.23)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(review.visibility == ReviewVisibility.anonymous ? '@anonimo' : review.username ?? '@anonimo', style: GoogleFonts.inter(color: _accent, fontSize: 6.8, fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          Row(children: List.generate(5, (index) => Icon(index < review.rating ? Icons.star_rounded : Icons.star_border_rounded, color: _gold, size: 13))),
          if (review.reviewText?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(review.reviewText!, style: GoogleFonts.merriweather(color: _textPrimary, fontSize: 7.7, height: 1.45)),
          ],
        ],
      ),
    );
  }

  void _openReviewEditor() {
    if (_guardGuestAction()) return;
    if (_reviews?.loaded != true || _reviews?.busy == true) {
      _storyReviewMessage('Las reseñas aún no están disponibles.');
      return;
    }

    _updateState(() {
      _draftRating = _rating;
      _draftReviewIsPublic = _reviewIsPublic;
      _reviewController.text = _reviewText;
      _reviewEditorOpen = true;
    });
  }

  void _cancelReviewEditing() {
    _updateState(() {
      _reviewEditorOpen = false;
      _draftRating = _rating;
      _draftReviewIsPublic = _reviewIsPublic;
      _reviewController.text = _reviewText;
    });
  }

  Future<void> _publishReview() async {
    if (_guardGuestAction()) return;
    final reviews = _reviews;
    if (reviews == null || reviews.busy || !reviews.loaded) return;
    final text = _reviewController.text.trim();
    final visibility = _draftReviewIsPublic
        ? ReviewVisibility.public
        : reviews.ownReview?.visibility == ReviewVisibility.private
            ? ReviewVisibility.private
            : ReviewVisibility.anonymous;
    final saved = await reviews.save(rating: _draftRating, text: text, visibility: visibility);
    if (!mounted) return;
    if (saved) _updateState(() => _reviewEditorOpen = false);
    if (reviews.error != null) _storyReviewMessage(reviews.error!);
  }

  Future<void> _deleteReview() async {
    if (_guardGuestAction()) return;
    final reviews = _reviews;
    if (reviews == null || reviews.busy) return;
    final confirmed = await showDialog<bool>(context: context, builder: (context) => _socialDialog(context,
      title: 'Eliminar reseña',
      content: _socialDialogMessage('¿Quieres eliminar tu valoración y reseña?'),
      actions: [
        _socialDialogButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        _socialDialogButton(primary: true, onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
      ],
    ));
    if (!mounted || confirmed != true) return;
    await reviews.delete();
    if (mounted && reviews.error != null) _storyReviewMessage(reviews.error!);
  }

  // Visual conventions reused from the original report and review editors.
  Widget _socialDialog(BuildContext dialogContext, {required String title, required Widget content, required List<Widget> actions}) {
    return SafeArea(
      child: AnimatedPadding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(dialogContext).viewInsets.bottom),
        duration: const Duration(milliseconds: 180),
        child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(dialogContext).size.width * 0.84,
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: _gold.withValues(alpha: 0.28)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: GoogleFonts.merriweather(fontSize: 13.5, fontWeight: FontWeight.w700, color: _textPrimary)),
                  const SizedBox(height: 12),
                  content,
                  const SizedBox(height: 12),
                  Row(children: [for (var i = 0; i < actions.length; i++) ...[if (i > 0) const SizedBox(width: 8), Expanded(child: actions[i])]]),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _socialDialogMessage(String message) => Text(message, style: GoogleFonts.inter(color: _textSecondary, fontSize: 8, height: 1.45));

  Widget _socialDialogButton({required VoidCallback? onPressed, required Widget child, bool primary = false}) {
    final textStyle = GoogleFonts.inter(fontSize: 7.4, fontWeight: FontWeight.w800);
    return SizedBox(
      height: 36,
      child: primary
          ? FilledButton(onPressed: onPressed, style: FilledButton.styleFrom(backgroundColor: _accent, disabledBackgroundColor: _accent.withValues(alpha: 0.32), foregroundColor: AppColors.background, textStyle: textStyle, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))), child: child)
          : OutlinedButton(onPressed: onPressed, style: OutlinedButton.styleFrom(foregroundColor: _textPrimary, side: BorderSide(color: _gold.withValues(alpha: 0.34)), textStyle: textStyle, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))), child: child),
    );
  }

  void _storyReviewMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
