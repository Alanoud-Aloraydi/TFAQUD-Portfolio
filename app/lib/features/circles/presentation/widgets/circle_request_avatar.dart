import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// An hourglass portrait for pending invitations.
class CircleRequestAvatar extends StatelessWidget {
  const CircleRequestAvatar.waiting({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: AppSizes.avatar,
        height: AppSizes.avatar,
        alignment: Alignment.center,
        decoration: const ShapeDecoration(
          color: AppSemanticColors.surfaceAttention,
          shape: CircleBorder(),
        ),
        child: const Icon(
          AppIcons.hourglass,
          size: AppSizes.iconSmall,
          color: AppSemanticColors.doseDueMarker,
        ),
      ),
    );
  }
}
