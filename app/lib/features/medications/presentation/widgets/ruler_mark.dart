import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/features/medications/presentation/widgets/ruler_look.dart';
import 'package:flutter/material.dart';

/// The fixed mark, over the number chosen.
class RulerMark extends StatelessWidget {
  const RulerMark({super.key, this.look = const RulerLook()});

  final RulerLook look;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 3 * look.scale,
          height: 34 * look.scale,
          decoration: BoxDecoration(
            color: look.mark,
            borderRadius: BorderRadius.circular(AppRadius.capsule),
          ),
        ),
      ),
    );
  }
}
