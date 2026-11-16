import 'package:app/features/medications/presentation/models/medication_form_data.dart';

/// Describes one medication form validation issue.
class MedicationFormIssue {
  const MedicationFormIssue(this.field, {this.scheduleIndex});

  final MedicationFormField field;
  final int? scheduleIndex;
}
