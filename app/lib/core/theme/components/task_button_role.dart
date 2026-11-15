import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The buttons under a task that is due, one look per answer. Each has its
/// own color and icon, so the answer is found at a glance; all have one
/// height (48), one text and one shape, so no row is a mix of sizes; and
/// every edge is at least 3:1 on the white card (WCAG 1.4.11), so each one
/// reads as something to press.
enum TaskButtonRole {
  /// «انأخذت», «تسجيل قراءة», «حضرت»: violet, as every main action.
  answer(AppColors.leaf, AppColors.inkViolet, AppColors.ink),

  /// «ذكّرني لاحقًا»: honey, the color of a time that waits.
  later(AppColors.honeyLight, AppColors.honeyDeep, AppColors.warning),

  /// «انأخذت بوقت سابق»: blue, a time of its own.
  earlier(AppColors.infoLight, AppColors.info, AppColors.info),

  /// «تخطي» and «إلغاء»: plain, with a grey edge that shows it is a button.
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
