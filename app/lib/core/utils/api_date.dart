/// [date] as the API's calendar date, `YYYY-MM-DD`.
///
/// Written by hand so that no locale can change the digits (an Arabic
/// locale would otherwise write ٠-٩). Every request body that sends a date
/// without a time, such as a birth date, goes through here.
String apiDate(DateTime date) {
  final String year = date.year.toString().padLeft(4, '0');
  final String month = date.month.toString().padLeft(2, '0');
  final String day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
