import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Who the app speaks to about a circle's care, and the words for each.
///
/// The patient reads their own care in the second person: «تم تسجيل إنك
/// أخذت الجرعة», «أدويتك الحالية». Someone caring for them reads the
/// patient's name in its place: «تم تسجيل أخذ محمود للجرعة», «أدوية محمود
/// الحالية». The app does not know whether the patient is a man or a woman,
/// so the caregiver's lines name the patient without a verb that would
/// guess it (the copy guide's neutral wording).
///
/// The words for a caregiver are a sibling key ending in `_other`, whose
/// first `{}` is the patient's name. A circle the app has not heard of yet
/// (or a key without a caregiver version) keeps the patient's words, as
/// before.
abstract final class CareVoice {
  static final Map<String, String> _patients = <String, String>{};

  /// Called each time the account's circles are read (`/home`): the
  /// patient's name for each circle the viewer cares for, and nothing for
  /// a circle where the viewer is the patient.
  static void update(Map<String, String?> patientNameByCircle) {
    _patients
      ..clear()
      ..addEntries(<MapEntry<String, String>>[
        for (final MapEntry<String, String?> item
            in patientNameByCircle.entries)
          if (item.value case final String name when name.trim().isNotEmpty)
            MapEntry<String, String>(item.key, name.trim()),
      ]);
  }

  /// Forgets every circle (on sign-out).
  static void clear() => _patients.clear();

  /// The patient's name when the viewer cares for someone else in
  /// [circleId]; null when the viewer is the patient, or not known.
  static String? patientOf(String? circleId) =>
      circleId == null ? null : _patients[circleId];

  /// [key] for the patient, or `${key}_other` with the patient's name first
  /// for someone caring for them.
  static String tr(
    BuildContext context,
    String? circleId,
    String key, {
    List<String> args = const <String>[],
  }) {
    final String? patient = patientOf(circleId);
    final String other = '${key}_other';
    if (patient != null && other.trExists()) {
      return context.tr(other, args: <String>[patient, ...args]);
    }
    return context.tr(key, args: args);
  }
}
