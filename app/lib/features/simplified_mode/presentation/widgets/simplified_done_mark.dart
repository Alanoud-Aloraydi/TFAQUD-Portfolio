import 'package:app/core/constants/app_icons.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

/// The mark of something done, in the colours of the detailed mode's «تم
/// أخذها»: a green check on the pale green, ringed in the same green so it
/// stands on any ground. The same on «تم، يعطيك العافية» and on the home's
/// «خلّصت مهام اليوم». Decorative: the words beside it say what was done.
class SimplifiedDoneMark extends StatelessWidget {
  const SimplifiedDoneMark({super.key, required this.size});

  /// The circle's width; the check is half of it.
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: SimplifiedStyle.successTint,
        shape: BoxShape.circle,
        border: Border.all(color: SimplifiedStyle.success, width: size / 36),
      ),
      child: Icon(
        AppIcons.check,
        size: size / 2,
        color: SimplifiedStyle.success,
      ),
    ),
  );
}
