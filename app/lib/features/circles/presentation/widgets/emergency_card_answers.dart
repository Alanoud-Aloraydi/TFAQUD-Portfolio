import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/medical_options.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';

/// The medical answers of the emergency card, in the card's language.
extension EmergencyCardAnswers on EmergencyCardText {
  String conditions(ConditionsDraft? answer) {
    if (answer == null) return t('unknown');
    if (answer.answer == ListAnswer.none) return t('no_conditions');
    return join(<String>[
      for (final String value in answer.codes)
        value == MedicalOptions.other
            ? (answer.other ?? '')
            : code('condition', value),
    ]);
  }

  /// The allergies that are listed, or null when there are none to show in
  /// the red box (none, or nobody answered).
  String? allergies(AllergiesDraft? answer) {
    if (answer == null || answer.answer == ListAnswer.none) return null;
    final String joined = join(<String>[
      for (final String value in answer.medication)
        value == MedicalOptions.other
            ? (answer.otherMedication ?? '')
            : code('medication', value),
      for (final String value in answer.food)
        value == MedicalOptions.other
            ? (answer.otherFood ?? '')
            : code('food', value),
    ]);
    return joined.isEmpty ? null : joined;
  }

  String noAllergies(AllergiesDraft? answer) =>
      answer == null ? t('unknown') : t('no_allergies');
}
