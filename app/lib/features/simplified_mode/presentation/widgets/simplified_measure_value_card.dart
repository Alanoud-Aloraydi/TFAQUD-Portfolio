import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// One typed measurement: the number large, its unit with it, and a frame
/// that marks the field being filled in. Read out as a single value.
class SimplifiedMeasureValueCard extends StatelessWidget {
  const SimplifiedMeasureValueCard({
    super.key,
    required this.value,
    required this.unit,
    required this.active,
    this.small = false,
  });

  final String value;
  final String unit;
  final bool active;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final Widget unitText = Text(
      unit,
      style: SimplifiedStyle.text(
        SimplifiedStyle.caption,
        weight: small ? AppTextTheme.medium : AppTextTheme.regular,
      ),
    );
    return Semantics(
      liveRegion: active,
      label: context.tr(
        'simplified_mode.a11y.typed_value',
        args: <String>[value.isEmpty ? unit : '$value $unit'],
      ),
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 116),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SimplifiedStyle.surface,
          borderRadius: BorderRadius.circular(SimplifiedStyle.radius),
          border: Border.all(
            color: active ? SimplifiedStyle.ink : SimplifiedStyle.disabled,
            width: active ? 3 : 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (small) unitText,
            // Numbers read left to right in Arabic too.
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                value.isEmpty ? '–' : value,
                style: SimplifiedStyle.head(
                  small ? SimplifiedStyle.number : 60,
                  height: 1.1,
                ),
              ),
            ),
            if (!small) unitText,
          ],
        ),
      ),
    );
  }
}
