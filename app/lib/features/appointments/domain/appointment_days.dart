/// The days of a booking, each its own visit: the main day first (the one
/// «يوم الموعد» shows and changes), then the added ones, oldest first.
library;

/// [days] with [chosen] as the main day; a day already added is not kept
/// twice.
List<DateTime> withMainDay(List<DateTime> days, DateTime chosen) => <DateTime>[
  chosen,
  ...days.skip(1).where((DateTime day) => day != chosen),
];

/// [days] with [chosen] added after the main day; unchanged when it is
/// already there. With no day yet it becomes the main one.
List<DateTime> withAddedDay(List<DateTime> days, DateTime chosen) {
  if (days.contains(chosen)) return days;
  if (days.isEmpty) return <DateTime>[chosen];
  return <DateTime>[
    days.first,
    ...(<DateTime>[...days.skip(1), chosen]..sort()),
  ];
}

/// The day after the latest one, where adding opens; null with none.
DateTime? dayAfterLast(List<DateTime> days) => days.isEmpty
    ? null
    : days
          .reduce((DateTime a, DateTime b) => a.isAfter(b) ? a : b)
          .add(const Duration(days: 1));
