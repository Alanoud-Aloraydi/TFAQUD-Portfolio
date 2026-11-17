import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The buttons under a task that is due, in two levels: the one answer the
/// task asks for is the tallest thing on the card and the only one in the
/// circle's violet, and the choices beside it are a full honey yellow and
/// a grey. The answer has the fill and words of every main action, as
/// «إضافة عضو» has, so the app's one «do it» colour is the same
/// everywhere.
///
/// They have no edge, as the status pills beside them («حان وقتها») have
/// none: a fill alone, so a card holds soft shapes rather than ruled lines.
/// A fill is under the 3:1 a boundary would need, so what identifies these
/// buttons is their words, which read at 7.9, 10.2 and 8.9 on their own
/// fill, and their icons.
enum TaskButtonRole {
  /// «انأخذت», «تسجيل قراءة», «حضرت»: the one answer, in the violet and
  /// ink of every main action («إضافة عضو»).
  answer(AppColors.leaf, AppColors.ink),

  /// «ذكّرني لاحقًا»: putting the task off, in the honey the app warns
  /// with, told also by its bell. The full honey, not its pale tint: on the
  /// cream of a late dose's card the tint did not show at all (1.0:1).
  later(AppColors.honey, AppColors.ink),

  /// «تخطي» and «إلغاء»: letting the task go, in grey, told also by its
  /// minus.
  skip(AppColors.slateMist, AppColors.slate);

  const TaskButtonRole(this.fill, this.ink);

  /// Its fill, and the color of its words and icon.
  final Color fill;
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
    side: BorderSide.none,
    textStyle: this == answer ? _answerWords : _words,
  );
}
