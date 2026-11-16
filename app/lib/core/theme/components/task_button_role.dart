import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The buttons under a task that is due, in two levels: the one answer the
/// task asks for is filled, every other choice is plain. Four pale fills
/// told them apart before, but they sat within 1.1 of each other in
/// lightness, so the card read as busy while nothing stood out — and the
/// filled answer among them was the palest thing on it. The icon and the
/// words name each choice now; the color only says which one is the
/// action. All are [AppSizes.button] high, one text and one shape, and
/// every edge is at least 3:1 on the white card (WCAG 1.4.11).
enum TaskButtonRole {
  /// «انأخذت», «تسجيل قراءة», «حضرت»: the one filled button of a task, in
  /// the deep violet every main action uses. Its pale fill read 1.9:1 on a
  /// white card, under the 3:1 a control needs; filled it reads 12.1:1.
  answer(AppColors.inkViolet, AppColors.inkViolet, AppColors.surface),

  /// «ذكّرني لاحقًا»: a choice beside the answer, told by its bell.
  later(AppColors.surface, AppColors.stone, AppColors.slate),

  /// «انأخذت بوقت سابق»: a choice beside the answer, told by its clock.
  earlier(AppColors.surface, AppColors.stone, AppColors.slate),

  /// «تخطي» and «إلغاء»: a choice beside the answer, told by its minus.
  skip(AppColors.surface, AppColors.stone, AppColors.slate);

  const TaskButtonRole(this.fill, this.edge, this.ink);

  /// Its fill, its 1px edge, and the color of its words and icon.
  final Color fill;
  final Color edge;
  final Color ink;

  static const TextStyle _words = TextStyle(
    fontFamily: AppTextTheme.fontFamily,
    fontSize: 15,
    height: 24 / 15,
    fontWeight: FontWeight.w600,
  );

  /// Its look: [AppSizes.button] high (taller only when the words wrap at a
  /// large text size), as wide as it is given.
  ButtonStyle get style => OutlinedButton.styleFrom(
    minimumSize: const Size(0, AppSizes.button),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    shape: const StadiumBorder(),
    backgroundColor: fill,
    foregroundColor: ink,
    side: BorderSide(color: edge),
    textStyle: _words,
  );
}
