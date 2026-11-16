part of '../calendar_sync.dart';

/// What a [CalendarSync] reads from, and remembers between calls.
abstract class _CalendarState {
  _CalendarState(
    this._medications,
    this._measurements,
    this._appointments,
    this._snoozes,
    this._calendar,
    this._texts,
    this._now,
  );

  final MedicationsUseCase _medications;
  final MeasurementsUseCase _measurements;
  final AppointmentsUseCase _appointments;
  final ValueListenable<Map<String, TaskSnooze>>? _snoozes;
  final DeviceCalendar _calendar;
  final CalendarEventTexts _texts;

  /// The instant source; the system clock unless a test injects one.
  final DateTime Function() _now;

  List<ReminderCircle> _circles = const <ReminderCircle>[];

  /// Whether [sync] gave the circles yet. Before it, a refresh would find no
  /// circle and delete every event, to make them again a moment later.
  bool _synced = false;
  late final CoalescingRunner _runner = CoalescingRunner(_run);
  int _session = 0;

  /// Whether full calendar access was asked for in this run of the app.
  bool _askedForFull = false;
}
