import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/widgets/layout/plan_fact_row.dart';
import 'package:flutter/material.dart';

/// A person: photo or avatar, then [label] («أضافه», none under a title that
/// says it) and the name in bold. Every name the app shows has its picture.
class PlanPersonFact extends StatelessWidget {
  const PlanPersonFact({
    super.key,
    this.label,
    required this.name,
    required this.circleId,
    this.accountId,
    this.avatarCode,
  });

  final String? label;
  final String name;
  final String circleId;
  final String? accountId;
  final String? avatarCode;

  @override
  Widget build(BuildContext context) => PlanFactRow(
    leading: PersonPhoto(
      name: name,
      // No account (an old plan): the avatar or the first letter, never
      // the patient's photo.
      photoPath: accountId == null ? '' : personPhotoPath(circleId, accountId),
      avatarCode: avatarCode,
      size: planFactLeadingSize,
    ),
    label: label,
    value: name,
  );
}
