import 'package:app/core/constants/app_icons.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// A phone-style keypad: 1 to 9, then 0 and «حذف».
class SimplifiedMeasureKeypad extends StatelessWidget {
  const SimplifiedMeasureKeypad({
    super.key,
    required this.onDigit,
    required this.onErase,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onErase;

  @override
  Widget build(BuildContext context) {
    Widget key(Widget label, VoidCallback onTap, {bool quiet = false}) =>
        Material(
          color: quiet ? SimplifiedStyle.clear : SimplifiedStyle.surface,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Center(child: label),
          ),
        );
    Widget digit(String value) => Semantics(
      label: context.tr('simplified_mode.a11y.digit', args: <String>[value]),
      excludeSemantics: true,
      child: Text(value, style: SimplifiedStyle.head(28)),
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.1,
        children: <Widget>[
          for (final String value in const <String>[
            '1', '2', '3', '4', '5', '6', '7', '8', '9', //
          ])
            key(digit(value), () => onDigit(value)),
          const SizedBox.shrink(),
          key(digit('0'), () => onDigit('0')),
          key(
            Semantics(
              label: context.tr('simplified_mode.erase_digit'),
              excludeSemantics: true,
              child: const Icon(AppIcons.back, size: 28),
            ),
            onErase,
            quiet: true,
          ),
        ],
      ),
    );
  }
}
