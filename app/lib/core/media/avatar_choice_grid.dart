import 'package:app/core/media/avatar_codes.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The avatars to choose from, four a row; [chosen] has a ring.
class AvatarChoiceGrid extends StatelessWidget {
  const AvatarChoiceGrid({
    super.key,
    required this.chosen,
    required this.onChosen,
  });

  final String? chosen;
  final ValueChanged<String> onChosen;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: avatarCodes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisExtent: 72,
      ),
      itemBuilder: (context, index) {
        final code = avatarCodes[index];
        // A square in the middle of the cell, so the picture stays a
        // circle whatever the cell's width is.
        return Center(
          child: GestureDetector(
            onTap: () => onChosen(code),
            child: AnimatedContainer(
              duration: AppMotion.fieldFeedback,
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: chosen == code
                    ? Border.all(
                        color: AppSemanticColors.actionPrimary,
                        width: 2,
                      )
                    : null,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/avatars/$code.png',
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Who sees the photo: the account's own photo ([frontCamera]) or a
/// patient's.
class PhotoVisibilityNote extends StatelessWidget {
  const PhotoVisibilityNote({super.key, required this.frontCamera});

  final bool frontCamera;

  @override
  Widget build(BuildContext context) {
    return Text(
      context.tr(
        frontCamera ? 'photos.account_visibility' : 'photos.patient_visibility',
      ),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
