/// Which appointments «السجل» shows: every one, the coming ones, or the
/// ones already behind.
enum AppointmentRecordFilter {
  all,
  upcoming,
  previous;

  /// Whether an appointment belongs in the list; [upcoming] is one still
  /// scheduled and not yet past.
  bool keeps({required bool isUpcoming}) => switch (this) {
    all => true,
    AppointmentRecordFilter.upcoming => isUpcoming,
    previous => !isUpcoming,
  };

  /// The key of its words, under `appointments.filters`.
  String get labelKey => 'appointments.filters.$name';
}
