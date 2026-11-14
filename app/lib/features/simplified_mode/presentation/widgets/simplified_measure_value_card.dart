import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// One typed measurement: the number large, its unit with it, and a frame
/// that marks the field being filled in. Read out as a single value. A
/// [small] card is one of a blood pressure's two numbers: its name at the
/// start and the number at the end, one card under the other.
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
        small ? SimplifiedStyle.body : SimplifiedStyle.caption,
        weight: small ? AppTextTheme.medium : AppTextTheme.regular,
      ),
    );
    // Numbers read left to right in Arabic too.
    final Widget number = Text(
      value.isEmpty ? '–' : value,
      textDirection: TextDirection.ltr,
      style: SimplifiedStyle.head(
        small ? SimplifiedStyle.number : 60,
        height: 1.1,
      ),
    );
    return Semantics(
      liveRegion: active,
      label: spoken(
        context.tr(
          'simplified_mode.a11y.typed_value',
          args: <String>[value.isEmpty ? unit : '$value $unit'],
        ),
      ),
      excludeSemantics: true,
      child: Container(
        constraints: BoxConstraints(minHeight: small ? 76 : 116),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SimplifiedStyle.surface,
          borderRadius: BorderRadius.circular(SimplifiedStyle.radius),
          border: Border.all(
            color: active ? SimplifiedStyle.ink : SimplifiedStyle.disabled,
            width: active ? 3 : 2,
          ),
        ),
        child: small
            ? Row(
                children: <Widget>[
                  Expanded(child: unitText),
                  number,
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[number, unitText],
              ),
      ),
    );
  }
}
