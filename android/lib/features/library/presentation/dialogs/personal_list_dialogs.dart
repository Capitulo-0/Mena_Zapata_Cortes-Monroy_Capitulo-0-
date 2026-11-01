import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/book_status.dart';
import '../../models/library_book.dart';
import '../../models/personal_library_list.dart';

class PersonalListDialogs {
  const PersonalListDialogs._();

  static Future<PersonalLibraryList?> showCreateListSheet({
    required BuildContext context,
  }) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    var selectedEmoji = '♥';
    var isCreating = false;
    PersonalLibraryList? result;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.60),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final canCreate =
                nameController.text.trim().isNotEmpty && !isCreating;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 9, 18, 20),
                decoration: BoxDecoration(
                  color: AppColors.backgroundOf(context),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.gold.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 38,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.deepOf(context),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'CREAR NUEVA LISTA',
                                style: GoogleFonts.cinzel(
                                  color: AppColors.textPrimaryOf(context),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '✦',
                              style: TextStyle(
                                color: AppColors.goldOf(context),
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _label(context, 'Ícono de la lista *'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 58,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.deepOf(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.goldOf(context)
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                selectedEmoji,
                                style: const TextStyle(fontSize: 23),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: isCreating
                                    ? null
                                    : () async {
                                        final emoji = await showEmojiPicker(
                                          context: context,
                                          selectedEmoji: selectedEmoji,
                                        );

                                        if (emoji == null ||
                                            !sheetContext.mounted) {
                                          return;
                                        }

                                        setSheetState(() {
                                          selectedEmoji = emoji;
                                        });
                                      },
                                borderRadius: BorderRadius.circular(11),
                                child: Container(
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceOf(context),
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(
                                      color: AppColors.gold.withValues(
                                        alpha: 0.45,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.emoji_emotions_outlined,
                                        size: 16,
                                        color: AppColors.goldOf(context),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Más emojis',
                                        style: GoogleFonts.inter(
                                          color:
                                              AppColors.textPrimaryOf(context),
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _label(context, 'Nombre de la lista *'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameController,
                          enabled: !isCreating,
                          maxLength: 50,
                          onChanged: (_) => setSheetState(() {}),
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimaryOf(context),
                            fontSize: 9.5,
                          ),
                          decoration: _inputDecoration(
                            context,
                            hint: 'Ej: Clásicos, Lecturas 2026...',
                            icon: Icons.menu_book_outlined,
                          ).copyWith(counterText: ''),
                        ),
                        const SizedBox(height: 13),
                        _label(context, 'Descripción (opcional)'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descriptionController,
                          enabled: !isCreating,
                          minLines: 3,
                          maxLines: 4,
                          maxLength: 180,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimaryOf(context),
                            fontSize: 9,
                            height: 1.4,
                          ),
                          decoration: _inputDecoration(
                            context,
                            hint: 'Cuéntanos de qué trata esta lista...',
                            icon: Icons.description_outlined,
                          ).copyWith(counterText: ''),
                        ),
                        const SizedBox(height: 17),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: OutlinedButton(
                                  onPressed: isCreating
                                      ? null
                                      : () =>
                                          Navigator.of(sheetContext).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        AppColors.textPrimaryOf(context),
                                    side: BorderSide(
                                      color: AppColors.goldOf(context),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancelar',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: FilledButton(
                                  onPressed: canCreate
                                      ? () async {
                                          FocusScope.of(context).unfocus();

                                          setSheetState(() {
                                            isCreating = true;
                                          });

                                          await Future<void>.delayed(
                                            const Duration(milliseconds: 1000),
                                          );

                                          if (!sheetContext.mounted) return;

                                          result = PersonalLibraryList(
                                            name: nameController.text.trim(),
                                            description:
                                                descriptionController.text.trim(),
                                            emoji: selectedEmoji,
                                          );

                                          Navigator.of(sheetContext).pop();
                                        }
                                      : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        AppColors.deepOf(context),
                                    disabledBackgroundColor: isCreating
                                        ? Colors.grey.shade600
                                        : AppColors.deepOf(context)
                                            .withValues(alpha: 0.30),
                                    foregroundColor:
                                        AppColors.backgroundOf(context),
                                    disabledForegroundColor:
                                        AppColors.backgroundOf(context)
                                            .withValues(alpha: 0.88),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                  ),
                                  child: isCreating
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 13,
                                              height: 13,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 1.8,
                                                color:
                                                    AppColors.backgroundOf(
                                                  context,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 7),
                                            Text(
                                              'Creando lista...',
                                              style: GoogleFonts.inter(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          'Crear lista',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
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
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 300));
    nameController.dispose();
    descriptionController.dispose();

    return result;
  }

  static Future<PersonalLibraryList?> showEditListSheet({
    required BuildContext context,
    required PersonalLibraryList list,
  }) async {
    final nameController = TextEditingController(text: list.name);
    final descriptionController =
        TextEditingController(text: list.description);

    var selectedEmoji = list.emoji;
    PersonalLibraryList? result;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final canSave = nameController.text.trim().isNotEmpty;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 9, 18, 20),
                decoration: BoxDecoration(
                  color: AppColors.backgroundOf(context),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(26),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.gold.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 38,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.deepOf(context),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'EDITAR LISTA',
                          style: GoogleFonts.cinzel(
                            color: AppColors.textPrimaryOf(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _label(context, 'Ícono de la lista *'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 58,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.deepOf(context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                selectedEmoji,
                                style: const TextStyle(fontSize: 23),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final emoji = await showEmojiPicker(
                                    context: context,
                                    selectedEmoji: selectedEmoji,
                                  );

                                  if (emoji == null ||
                                      !sheetContext.mounted) {
                                    return;
                                  }

                                  setSheetState(() {
                                    selectedEmoji = emoji;
                                  });
                                },
                                borderRadius: BorderRadius.circular(11),
                                child: Container(
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceOf(context),
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(
                                      color: AppColors.gold.withValues(
                                        alpha: 0.45,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Más emojis',
                                    style: GoogleFonts.inter(
                                      color:
                                          AppColors.textPrimaryOf(context),
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _label(context, 'Nombre de la lista *'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameController,
                          maxLength: 50,
                          onChanged: (_) => setSheetState(() {}),
                          decoration: _inputDecoration(
                            context,
                            hint: 'Nombre de la lista',
                            icon: Icons.menu_book_outlined,
                          ).copyWith(counterText: ''),
                        ),
                        const SizedBox(height: 13),
                        _label(context, 'Descripción (opcional)'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descriptionController,
                          minLines: 3,
                          maxLines: 4,
                          maxLength: 180,
                          decoration: _inputDecoration(
                            context,
                            hint: 'Descripción de tu lista...',
                            icon: Icons.description_outlined,
                          ).copyWith(counterText: ''),
                        ),
                        const SizedBox(height: 17),
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: FilledButton(
                            onPressed: canSave
                                ? () {
                                    result = list.copyWith(
                                      name: nameController.text.trim(),
                                      description:
                                          descriptionController.text.trim(),
                                      emoji: selectedEmoji,
                                    );
                                    Navigator.of(sheetContext).pop();
                                  }
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  AppColors.deepOf(context),
                              foregroundColor:
                                  AppColors.backgroundOf(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                            child: Text(
                              'Guardar cambios',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 300));
    nameController.dispose();
    descriptionController.dispose();

    return result;
  }

  static Future<String?> showEmojiPicker({
    required BuildContext context,
    required String selectedEmoji,
  }) async {
    const emojis = <String>[
      '♥',
      '📖',
      '🔖',
      '☆',
      '✦',
      '📚',
      '☕',
      '🎧',
      '🎬',
      '🍃',
      '☾',
      '☀',
      '🌸',
      '⛰',
      '🔥',
    ];

    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.backgroundOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Seleccionar emoji',
                        style: GoogleFonts.merriweather(
                          color: AppColors.textPrimaryOf(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: emojis.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 7,
                    crossAxisSpacing: 7,
                  ),
                  itemBuilder: (context, index) {
                    final emoji = emojis[index];
                    final active = emoji == selectedEmoji;

                    return InkWell(
                      onTap: () =>
                          Navigator.of(dialogContext).pop(emoji),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.goldOf(context)
                                  .withValues(alpha: 0.22)
                              : AppColors.surfaceOf(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: active
                                ? AppColors.goldOf(context)
                                : AppColors.gold.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<Set<int>?> showAddBooksSheet({
    required BuildContext context,
    required PersonalLibraryList list,
    required List<LibraryBook> booksInLibrary,
    required Map<int, BookStatus> statuses,
  }) async {
    final selectedBookIds = <int>{...list.bookIds};
    var isSaving = false;
    Set<int>? result;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final availableBooks = booksInLibrary.where((book) {
              final status = statuses[book.id];
              final validStatus =
                  status == BookStatus.leyendo ||
                  status == BookStatus.porLeer;

              return validStatus && !selectedBookIds.contains(book.id);
            }).toList();

            final selectedBooks = booksInLibrary.where((book) {
              return selectedBookIds.contains(book.id);
            }).toList();

            final hasChanges =
                !Set<int>.from(list.bookIds).containsAll(selectedBookIds) ||
                !selectedBookIds.containsAll(list.bookIds);
            final canSave = hasChanges && !isSaving;

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.78,
              minChildSize: 0.58,
              maxChildSize: 0.94,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundOf(context),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.gold.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(18, 9, 18, 24),
                      children: [
                        Center(
                          child: Container(
                            width: 38,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.deepOf(context),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.goldOf(context)
                                    .withValues(alpha: 0.13),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Text(
                                list.emoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AGREGAR LIBROS',
                                    style: GoogleFonts.cinzel(
                                      color:
                                          AppColors.textPrimaryOf(context),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.35,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    list.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.merriweather(
                                      color:
                                          AppColors.textPrimaryOf(context),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 34,
                              child: FilledButton.icon(
                                onPressed: canSave
                                    ? () async {
                                        setSheetState(() {
                                          isSaving = true;
                                        });

                                        await Future<void>.delayed(
                                          const Duration(
                                            milliseconds: 1000,
                                          ),
                                        );

                                        if (!sheetContext.mounted) return;

                                        result = Set<int>.from(
                                          selectedBookIds,
                                        );

                                        Navigator.of(sheetContext).pop();
                                      }
                                    : null,
                                icon: isSaving
                                    ? const SizedBox(
                                        width: 13,
                                        height: 13,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.8,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.save_outlined,
                                        size: 14,
                                      ),
                                label: Text(
                                  isSaving ? 'Guardando...' : 'Guardar',
                                  style: GoogleFonts.inter(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      AppColors.deepOf(context),
                                  disabledBackgroundColor: isSaving
                                      ? Colors.grey.shade600
                                      : AppColors.deepOf(context)
                                          .withValues(alpha: 0.22),
                                  foregroundColor:
                                      AppColors.backgroundOf(context),
                                  disabledForegroundColor: isSaving
                                      ? Colors.white
                                      : AppColors.textSecondaryOf(context),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Selecciona libros que ya estén en tu biblioteca con estado Leyendo o Por leer.',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondaryOf(context),
                            fontSize: 8,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _bookSectionTitle(context, 'LIBROS DISPONIBLES'),
                        const SizedBox(height: 9),
                        if (availableBooks.isEmpty)
                          _emptyBooksMessage(
                            context,
                            icon: Icons.library_books_outlined,
                            title: 'No hay más libros disponibles',
                            message:
                                'Todos los libros disponibles ya están agregados o no están en Leyendo / Por leer.',
                          )
                        else
                          ...availableBooks.map(
                            (book) => _bookSelectionCard(
                              context,
                              book: book,
                              actionLabel: 'Agregar',
                              actionIcon: null,
                              onTap: isSaving
                                  ? null
                                  : () {
                                      setSheetState(() {
                                        selectedBookIds.add(book.id);
                                      });
                                    },
                            ),
                          ),
                        const SizedBox(height: 18),
                        _bookSectionTitle(
                          context,
                          'LIBROS AGREGADOS',
                          trailing: '${selectedBooks.length}',
                        ),
                        const SizedBox(height: 9),
                        if (selectedBooks.isEmpty)
                          _emptyBooksMessage(
                            context,
                            icon: Icons.playlist_add_rounded,
                            title: 'Aún no agregas libros',
                            message:
                                'Los libros que selecciones aparecerán en esta sección antes de guardar.',
                          )
                        else
                          ...selectedBooks.map(
                            (book) => _bookSelectionCard(
                              context,
                              book: book,
                              actionLabel: 'Quitar',
                              actionIcon:
                                  Icons.remove_circle_outline_rounded,
                              outlined: true,
                              onTap: isSaving
                                  ? null
                                  : () {
                                      setSheetState(() {
                                        selectedBookIds.remove(book.id);
                                      });
                                    },
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    return result;
  }

  static Future<void> showListDetail({
    required BuildContext context,
    required PersonalLibraryList list,
    required List<LibraryBook> books,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.68,
          minChildSize: 0.50,
          maxChildSize: 0.90,
          builder: (context, scrollController) {
            final selectedBooks = books
                .where((book) => list.bookIds.contains(book.id))
                .toList();

            return Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundOf(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                border: Border(
                  top: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 9, 18, 24),
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.deepOf(context),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            list.emoji,
                            style: const TextStyle(fontSize: 25),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                list.name,
                                style: GoogleFonts.cinzel(
                                  color: AppColors.textPrimaryOf(context),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (list.description.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  list.description,
                                  style: GoogleFonts.inter(
                                    color:
                                        AppColors.textSecondaryOf(context),
                                    fontSize: 8.5,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _bookSectionTitle(
                      context,
                      'LIBROS AGREGADOS',
                      trailing: '${selectedBooks.length}',
                    ),
                    const SizedBox(height: 10),
                    if (selectedBooks.isEmpty)
                      _emptyBooksMessage(
                        context,
                        icon: Icons.library_books_outlined,
                        title: 'Aún no hay libros agregados',
                        message:
                            'Acá aparecerán los libros que agregues a tu lista personal.',
                      )
                    else
                      ...selectedBooks.map(
                        (book) => _bookInfoCard(context, book),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _label(BuildContext context, String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: AppColors.textPrimaryOf(context),
        fontSize: 8.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  static InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: AppColors.textSecondaryOf(context),
        fontSize: 8.5,
      ),
      prefixIcon: Icon(
        icon,
        color: AppColors.deepOf(context),
        size: 18,
      ),
      filled: true,
      fillColor: AppColors.surfaceOf(context),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(
          color: AppColors.gold.withValues(alpha: 0.50),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(
          color: AppColors.goldOf(context),
          width: 1.4,
        ),
      ),
    );
  }

  static Widget _bookSectionTitle(
    BuildContext context,
    String text, {
    String? trailing,
  }) {
    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.cinzel(
            color: AppColors.textPrimaryOf(context),
            fontSize: 9.4,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.35,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: AppColors.accentOf(context)
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              trailing,
              style: GoogleFonts.inter(
                color: AppColors.accentOf(context),
                fontSize: 6.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  static Widget _emptyBooksMessage(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 22,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 26,
            color: AppColors.goldOf(context),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.merriweather(
              color: AppColors.textPrimaryOf(context),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textSecondaryOf(context),
              fontSize: 7.4,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _bookSelectionCard(
    BuildContext context, {
    required LibraryBook book,
    required String actionLabel,
    required VoidCallback? onTap,
    IconData? actionIcon,
    bool outlined = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          children: [
            _cover(context, book.cover, 46, 64),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.merriweather(
                      color: AppColors.textPrimaryOf(context),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondaryOf(context),
                      fontSize: 7.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (outlined)
              OutlinedButton.icon(
                onPressed: onTap,
                icon: Icon(
                  actionIcon,
                  size: 13,
                ),
                label: Text(
                  actionLabel,
                  style: GoogleFonts.inter(
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentOf(context),
                  side: BorderSide(
                    color: AppColors.accentOf(context)
                        .withValues(alpha: 0.42),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              )
            else
              FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepOf(context),
                  foregroundColor: AppColors.backgroundOf(context),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: GoogleFonts.inter(
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _bookInfoCard(
    BuildContext context,
    LibraryBook book,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.26),
          ),
        ),
        child: Row(
          children: [
            _cover(context, book.cover, 40, 56),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.merriweather(
                      color: AppColors.textPrimaryOf(context),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondaryOf(context),
                      fontSize: 7,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _cover(
    BuildContext context,
    String url,
    double width,
    double height,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            return Container(
              color: AppColors.deepOf(context),
              alignment: Alignment.center,
              child: const Icon(
                Icons.menu_book_rounded,
                color: AppColors.gold,
              ),
            );
          },
        ),
      ),
    );
  }
}
