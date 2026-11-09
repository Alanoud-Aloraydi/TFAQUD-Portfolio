import 'package:easy_localization/easy_localization.dart';

/// [name] with «ال» before it, as Arabic says a known thing: «الأنسولين».
/// A name that has it already («البنادول»), or that is not written in
/// Arabic («Panadol»), stays as it is.
String withArticle(String name) {
  final String value = name.trim();
  if (value.isEmpty || value.startsWith('ال')) return value;
  final int first = value.codeUnitAt(0);
  // The Arabic letters, hamza to yeh.
  final bool arabic = first >= 0x0621 && first <= 0x064A;
  return arabic ? 'ال$value' : value;
}

/// «عيادة السكري» for a specialty of the list (saved as its code,
/// «diabetes»); one the person wrote, as written.
String clinicName(String specialty) {
  final String key = 'appointments.specialties.$specialty';
  if (specialty == 'other' || !key.trExists()) return specialty;
  return '${'appointments.clinic'.tr()} ${key.tr()}';
}

/// «4:30 م» for "16:30", the same as the app's pages show a time.
String clockText(String time) {
  final List<String> parts = time.split(':');
  final int hour = int.parse(parts[0]);
  final int minute = int.parse(parts[1]);
  return '${hour % 12 == 0 ? 12 : hour % 12}:'
      '${minute.toString().padLeft(2, '0')} '
      '${(hour < 12 ? 'common.am' : 'common.pm').tr()}';
}
