/// The ready-made periods of the export sheet.
enum ExportRange { last7, last30, last90, custom, all }

/// A closed span of patient calendar days, both ends included.
class ExportPeriod {
  const ExportPeriod(this.start, this.end);

  /// The period of [range] ending on [today] (the patient's day). [earliest]
  /// opens «السجل كاملًا»; [custom] is the person's own span.
  factory ExportPeriod.of(
    ExportRange range, {
    required DateTime today,
    required DateTime earliest,
    ExportPeriod? custom,
  }) {
    final int? back = switch (range) {
      ExportRange.last7 => 6,
      ExportRange.last30 => 29,
      ExportRange.last90 => 89,
      ExportRange.custom => custom == null ? 29 : null,
      ExportRange.all => null,
    };
    if (range == ExportRange.custom && custom != null) return custom;
    if (back == null) return ExportPeriod(earliest, today);
    return ExportPeriod(
      DateTime(today.year, today.month, today.day - back),
      today,
    );
  }

  final DateTime start;
  final DateTime end;

  /// Whether the calendar day of [value] falls inside the period.
  bool contains(DateTime value) {
    final DateTime day = DateTime(value.year, value.month, value.day);
    final DateTime first = DateTime(start.year, start.month, start.day);
    final DateTime last = DateTime(end.year, end.month, end.day);
    return !day.isBefore(first) && !day.isAfter(last);
  }
}
