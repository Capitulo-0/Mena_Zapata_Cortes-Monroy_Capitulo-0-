import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/personal_library_list.dart';

class PersonalListsView extends StatelessWidget {
  const PersonalListsView({
    super.key,
    required this.lists,
    required this.onCreateList,
    required this.onOpenList,
    required this.onOpenMenu,
  });

  final List<PersonalLibraryList> lists;
  final VoidCallback onCreateList;
  final ValueChanged<int> onOpenList;
  final ValueChanged<int> onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MIS LISTAS PERSONALES',
          style: GoogleFonts.cinzel(
            color: AppColors.textPrimaryOf(context),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        if (lists.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.library_add_outlined,
                  color: AppColors.goldOf(context),
                  size: 26,
                ),
                const SizedBox(height: 8),
                Text(
                  'Aún no has creado listas',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.merriweather(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Crea una lista personal para organizar tus libros como quieras.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 7.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 38,
                  child: FilledButton.icon(
                    onPressed: onCreateList,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.deepOf(context),
                      foregroundColor: AppColors.goldOf(context),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(
                      Icons.add_box_outlined,
                      size: 16,
                    ),
                    label: Text(
                      'Crear lista',
                      style: GoogleFonts.inter(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(
            lists.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PersonalListCard(
                list: lists[index],
                onOpen: () => onOpenList(index),
                onOpenMenu: () => onOpenMenu(index),
              ),
            ),
          ),
      ],
    );
  }
}

class _PersonalListCard extends StatelessWidget {
  const _PersonalListCard({
    required this.list,
    required this.onOpen,
    required this.onOpenMenu,
  });

  final PersonalLibraryList list;
  final VoidCallback onOpen;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.40),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                list.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.merriweather(
                      color: AppColors.textPrimaryOf(context),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (list.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      list.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondaryOf(context),
                        fontSize: 7.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${list.bookIds.length}',
              style: GoogleFonts.inter(
                color: AppColors.accentOf(context),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: onOpenMenu,
              borderRadius: BorderRadius.circular(9),
              child: SizedBox(
                width: 30,
                height: 30,
                child: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
