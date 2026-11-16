import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_form_state.dart';
import 'package:flutter/material.dart';

/// The form that adds a medicine or changes one. [plan] is the medicine
/// being changed; null adds a new one.
class MedicationForm extends StatefulWidget {
  const MedicationForm({super.key, required this.circleId, this.plan});

  final String circleId;
  final MedicationPlan? plan;

  @override
  State<MedicationForm> createState() => MedicationFormState();
}
