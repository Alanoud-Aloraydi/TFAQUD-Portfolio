import 'package:app/core/l10n/medical_texts.dart';
import 'package:app/core/utils/birth_date_rules.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The card's words in the chosen language. Arabic reads the app's keys;
/// English reads `card_en`. Typed text (names, «other» items, medicine
/// names) is never translated. The answers themselves are put into words by
/// the `emergency_card_answers.dart` extension.
class EmergencyCardText {
  EmergencyCardText(this.context, {required this.english});

  final BuildContext context;
  final bool english;

  String t(String key, {List<String>? args}) =>
      context.tr(english ? 'card_en.$key' : 'emergency_card.$key', args: args);

  /// One code of a medical group, such as a condition or a food.
  String code(String group, String value) =>
      context.tr(english ? 'card_en.$group.$value' : 'medical.$group.$value');

  String form(String name) =>
      context.tr(english ? 'card_en.form.$name' : 'medications.form.$name');

  String unit(String name) =>
      context.tr(english ? 'card_en.unit.$name' : 'medications.unit.$name');

  /// The words typed for «أخرى» stay as typed in either language.
  String relation(EmergencyContact contact) =>
      english && contact.relationOther == null
      ? code('relation', contact.relation)
      : MedicalTexts.relation(context, contact);

  /// «8:00 ص» or «8:00 AM» for a plan's «HH:mm»: the card never shows a
  /// 24-hour clock, in either language.
  String clock(String time) {
    final List<String> parts = time.split(':');
    final int hour = int.tryParse(parts.first) ?? 0;
    final String minute = parts.length > 1 ? parts[1] : '00';
    return '${hour % 12 == 0 ? 12 : hour % 12}:$minute '
        '${t(hour < 12 ? 'am' : 'pm')}';
  }

  /// The items that have something in them, «، » between them.
  String join(List<String> items) =>
      items.where((String item) => item.trim().isNotEmpty).join(t('separator'));

  /// «72 سنة، مواليد 1954» or «72 years، born 1954».
  String age(DateTime birthDate) {
    // On the patient's today, where they live.
    final int years = BirthDateRules.ageOn(
      birthDate,
      PatientClockScope.of(context).today(),
    );
    final bool few = years >= 3 && years <= 10;
    return t(
      few ? 'age_few' : 'age_many',
      args: <String>['$years', '${birthDate.year}'],
    );
  }
}
