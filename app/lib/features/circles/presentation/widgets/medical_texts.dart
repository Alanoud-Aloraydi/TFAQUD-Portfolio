import 'package:app/features/auth/presentation/widgets/phone_field.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/medical_options.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// The words the medical file and the emergency card use for the saved
/// answers. A part nobody answered reads "غير محدد"; "none" is a real answer
/// and reads as one ("لا يوجد", "لا توجد حساسية").
abstract class MedicalTexts {
  MedicalTexts._();

  /// A blood type as a chip or a line shows it. The marks keep the sign after
  /// the letters inside right-to-left text.
  static String bloodTypeLabel(String type) => '\u200E$type\u200E';

  static String bloodType(BuildContext context, String? type) {
    if (type == null) return context.tr('circles.file_unknown');
    return bloodTypeLabel(type);
  }

  static String conditions(BuildContext context, ConditionsDraft? answer) {
    if (answer == null) return context.tr('circles.file_unknown');
    if (answer.answer == ListAnswer.none) {
      return context.tr('medical.condition.none');
    }
    return _join(context, <String>[
      for (final String code in answer.codes)
        code == MedicalOptions.other
            ? (answer.other ?? '')
            : context.tr('medical.condition.$code'),
    ]);
  }

  static String allergies(BuildContext context, AllergiesDraft? answer) {
    if (answer == null) return context.tr('circles.file_unknown');
    if (answer.answer == ListAnswer.none) {
      return context.tr('circles.no_allergies');
    }
    return _join(context, <String>[
      for (final String code in answer.medication)
        code == MedicalOptions.other
            ? (answer.otherMedication ?? '')
            : context.tr('medical.medication.$code'),
      for (final String code in answer.food)
        code == MedicalOptions.other
            ? (answer.otherFood ?? '')
            : context.tr('medical.food.$code'),
    ]);
  }

  static String relation(BuildContext context, EmergencyContact contact) =>
      context.tr('medical.relation.${contact.relation}');

  /// `+966 50 123 4567`, written with the digits 0-9. Shown left to right.
  static String phone(EmergencyContact contact) =>
      '+966 ${PhoneNumberFormatter.display(contact.nationalNumber)}';

  static String _join(BuildContext context, List<String> items) {
    final List<String> named = <String>[
      for (final String item in items)
        if (item.trim().isNotEmpty) item,
    ];
    return named.isEmpty
        ? context.tr('circles.file_unknown')
        : named.join('، ');
  }
}
