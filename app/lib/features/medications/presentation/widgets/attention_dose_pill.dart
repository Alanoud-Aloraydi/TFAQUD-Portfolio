import 'package:app/core/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_circle.dart';
import 'package:flutter/material.dart';

/// The medicine's photo beside a late dose, or a pill while it has none. It
/// is decoration; the name says what it is.
class AttentionDosePill extends StatelessWidget {
  const AttentionDosePill({
    super.key,
    required this.circleId,
    required this.planId,
  });

  final String circleId;
  final String planId;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: MedicationPhotoCircle(
        circleId: circleId,
        planId: planId,
        size: 34,
        fallback: CircleAvatar(
          radius: 17,
          backgroundColor: context.tokens.error.withValues(alpha: .08),
          child: Icon(
            TafaqodPhosphorIcons.pill,
            color: context.tokens.error,
            size: 18,
          ),
        ),
      ),
    );
  }
}
