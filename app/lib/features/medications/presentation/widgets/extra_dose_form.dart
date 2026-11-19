import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/extra_dose_form_state.dart';
import 'package:flutter/material.dart';

/// The fields of «سجّل جرعة الآن» once the medicines are in: which one,
/// how much, and when it was taken.
class ExtraDoseForm extends StatefulWidget {
  const ExtraDoseForm({super.key, required this.circleId, required this.plans});

  final String circleId;

  /// The medicines taken today, at least one.
  final List<MedicationPlan> plans;

  @override
  State<ExtraDoseForm> createState() => ExtraDoseFormState();
}
