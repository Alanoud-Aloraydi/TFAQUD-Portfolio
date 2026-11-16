import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';

/// The patient's own circle in [account], if it has one.
///
/// A simplified account is always the patient. Never fall back to a circle
/// they merely manage: every task, family member and medical fact on this
/// mode must belong to the person's own circle.
CareCircleSummary? simplifiedPatientCircle(HomeEntity account) =>
    account.circles.where((item) => item.isPatient).firstOrNull;

/// The family members the patient can phone: not the patient, not the
/// person using the phone, and with a number on file.
List<CircleMember> simplifiedFamily(CircleOverview? overview) => <CircleMember>[
  for (final CircleMember member in overview?.members ?? const <CircleMember>[])
    if (!member.isPatient && !member.isYou && member.phoneNumber != null)
      member,
];

/// Each medicine's reason, by plan id, for the plans that name one.
Map<String, String> simplifiedReasons(List<MedicationPlan>? plans) =>
    <String, String>{
      for (final MedicationPlan plan in plans ?? const <MedicationPlan>[])
        if (plan.version.reason case final String reason
            when reason.trim().isNotEmpty)
          plan.id: reason.trim(),
    };
