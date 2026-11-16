/// How a dose time repeats: on chosen weekdays, every few days from the
/// treatment's start («نذكرك كل 3 أيام»), or on chosen days of the month.
/// The app offers the first two; a monthly schedule saved before stays
/// monthly until it is edited. The API's words are the names.
enum ScheduleRepeat { weekly, monthly, interval }
