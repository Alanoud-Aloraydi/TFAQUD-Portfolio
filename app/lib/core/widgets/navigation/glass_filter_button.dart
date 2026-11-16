import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The filter of a list, without words: a round glass button with the
/// sliders, so it never crowds what it filters. Once something is chosen
/// ([active]) it fills with the circle's lavender, so a narrowed list is
/// never taken for the whole one. [label] is what is chosen, read out
/// after «تصفية»: «الكل», «نوفمبر 2026، خالد».
class GlassFilterButton extends StatelessWidget {
  const GlassFilterButton({
    super.key,
    required this.label,
    required this.active,
    required this.onPressed,
  });

  final String label;
  final bool active;
  final VoidCallback onPressed;

  /// Its one mark, also what its open menu grows from.
  static const Widget mark = Icon(
    CupertinoIcons.slider_horizontal_3,
    size: AppSizes.icon,
    color: AppSemanticColors.textPrimary,
  );

  @override
  Widget build(BuildContext context) {
    final Widget face = Material(
      color: active
          ? AppSemanticColors.actionPrimary
          : AppSemanticColors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Center(child: mark),
      ),
    );
    return Semantics(
      button: true,
      selected: active,
      label: spoken('${context.tr('history.filter')}: $label'),
      onTap: onPressed,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: AppSizes.touch,
        child: active
            ? face
            : GlassSurface(
                borderRadius: BorderRadius.circular(AppSizes.touch / 2),
                child: face,
              ),
      ),
    );
  }
}
