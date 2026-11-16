import 'package:app/core/constants/app_icons.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

/// The mark of something done: a white check on the palette's green, the
/// same on «تم، يعطيك العافية» and on the home's «خلّصت مهام اليوم».
/// Decorative: the words beside it say what was done.
class SimplifiedDoneMark extends StatelessWidget {
  const SimplifiedDoneMark({super.key, required this.size});

  /// The circle's width; the check is half of it.
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: SimplifiedStyle.success,
        shape: BoxShape.circle,
      ),
      child: Icon(
        AppIcons.check,
        size: size / 2,
        color: SimplifiedStyle.surface,
      ),
    ),
  );
}
