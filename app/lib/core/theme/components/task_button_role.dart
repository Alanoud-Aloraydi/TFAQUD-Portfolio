import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The buttons under a task that is due, in two levels: the one answer the
/// task asks for is the tallest thing on the card and the only one in the
/// circle's violet, and the choices beside it are a quieter yellow and
/// grey. Deep violet filled the answer before, which read as the heaviest
/// mark on a white card; the pale fill below is the tint «يحتاج انتباهك»
/// uses, so a card asks rather than shouts.
///
/// Each edge is one step deeper than the fill it surrounds, of the same
/// colour, so it reads as the shape of the fill rather than a line ruled
/// around it. That is under the 3:1 a boundary would need (1.9, 1.5 and
/// 1.7 on white), so what identifies these buttons is their words, which
/// read at 8.4, 6.1 and 8.9 on their own fill, and their icons.
enum TaskButtonRole {
  /// «انأخذت», «تسجيل قراءة», «حضرت»: the one answer, in the baby violet
  /// of «يحتاج انتباهك» with the violet every main action uses for its
  /// edge and its words.
  answer(AppColors.leafTintDeep, AppColors.leaf, AppColors.inkViolet),

  /// «ذكّرني لاحقًا»: putting the task off, in the honey the app warns
  /// with, told also by its bell.
  later(AppColors.honeyLight, AppColors.honey, AppColors.warning),

  /// «تخطي» and «إلغاء»: letting the task go, in grey, told also by its
  /// minus.
  skip(AppColors.slateMist, AppColors.slateSoft, AppColors.slate);

  const TaskButtonRole(this.fill, this.edge, this.ink);

  /// Its fill, its 1px edge, and the color of its words and icon.
  final Color fill;
  final Color edge;
  final Color ink;

  /// The answer stands a step taller than the choices under it.
  double get height => this == answer ? AppSizes.buttonAnswer : AppSizes.button;

  static const TextStyle _words = TextStyle(
    fontFamily: AppTextTheme.fontFamily,
    fontSize: 15,
    height: 24 / 15,
    fontWeight: FontWeight.w600,
  );

  /// The answer carries the card, so its words are a size up.
  static const TextStyle _answerWords = TextStyle(
    fontFamily: AppTextTheme.fontFamily,
    fontSize: 17,
    height: 24 / 17,
    fontWeight: FontWeight.w600,
  );

  /// Its look: [height] high (taller only when the words wrap at a large
  /// text size), as wide as it is given.
  ButtonStyle get style => OutlinedButton.styleFrom(
    minimumSize: Size(0, height),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    shape: const StadiumBorder(),
    backgroundColor: fill,
    foregroundColor: ink,
    side: BorderSide(color: edge),
    textStyle: this == answer ? _answerWords : _words,
  );
}
