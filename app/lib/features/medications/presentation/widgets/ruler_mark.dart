import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:flutter/material.dart';

/// The fixed mark, over the number chosen.
class RulerMark extends StatelessWidget {
  const RulerMark({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 3,
          height: 34,
          decoration: BoxDecoration(
            color: AppSemanticColors.pickerMark,
            borderRadius: BorderRadius.circular(AppRadius.capsule),
          ),
        ),
      ),
    );
  }
}
