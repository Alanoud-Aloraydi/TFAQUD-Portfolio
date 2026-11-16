import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

/// The frame of a typed measurement: a thick ink border on the field being
/// filled in and a thin grey one on the other. A [small] frame holds one of
/// a blood pressure's two numbers.
class SimplifiedMeasureFrame extends StatelessWidget {
  const SimplifiedMeasureFrame({
    super.key,
    required this.active,
    required this.small,
    required this.child,
  });

  final bool active;
  final bool small;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: child,
    );
  }
}
