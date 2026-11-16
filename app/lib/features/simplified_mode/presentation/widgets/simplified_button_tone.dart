import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

/// The look of a [SimplifiedButton]. The three a task uses borrow the
/// detailed mode's colours ([TaskButtonRole]), so «أخذته الآن» is the same
/// baby violet, «ذكّرني لاحقًا» the same honey and «ما أخذتها» the same
/// grey in both modes; the rest are the mode's own.
enum SimplifiedButtonTone {
  primary,
  secondary,
  danger,
  dark,
  quiet,
  answer(TaskButtonRole.answer),
  later(TaskButtonRole.later),
  skip(TaskButtonRole.skip);

  const SimplifiedButtonTone([this.role]);

  /// The task role whose colours this tone borrows; null for the mode's
  /// own buttons.
  final TaskButtonRole? role;

  /// Its fill, the colour of its words, and its edge. A task's button has
  /// no edge, as in the detailed mode: its fill, words and icon say it.
  (Color, Color, BorderSide) get paint {
    if (role case final TaskButtonRole role) {
      return (role.fill, role.ink, BorderSide.none);
    }
    return switch (this) {
      primary => (
        SimplifiedStyle.accentStrong,
        SimplifiedStyle.surface,
        BorderSide.none,
      ),
      secondary => (
        SimplifiedStyle.surface,
        SimplifiedStyle.ink,
        const BorderSide(color: SimplifiedStyle.control, width: 2),
      ),
      danger => (
        SimplifiedStyle.danger,
        SimplifiedStyle.surface,
        BorderSide.none,
      ),
      dark => (SimplifiedStyle.ink, SimplifiedStyle.surface, BorderSide.none),
      _ => (SimplifiedStyle.chip, SimplifiedStyle.ink, BorderSide.none),
    };
  }
}
