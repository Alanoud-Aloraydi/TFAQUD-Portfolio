/// The week as the app lists it, Saturday first, with ISO numbers
/// (1 Monday to 7 Sunday).
const List<int> weekOrder = <int>[6, 7, 1, 2, 3, 4, 5];

/// Every day of the week.
final Set<int> allWeekdays = Set<int>.unmodifiable(weekOrder);

/// Whether [days] holds all seven days.
bool isEveryDay(Iterable<int> days) => days.toSet().length == weekOrder.length;

/// The days after a tap on [day]. When every day is on, the tap picks that
/// one day alone, because the user is narrowing the week down; otherwise it
/// adds or removes the day.
Set<int> toggleWeekday(Set<int> current, int day) {
  if (isEveryDay(current)) return <int>{day};
  final Set<int> next = <int>{...current};
  if (!next.remove(day)) next.add(day);
  return next;
}
