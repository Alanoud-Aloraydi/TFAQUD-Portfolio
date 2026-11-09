import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_snooze.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:flutter_test/flutter_test.dart';

/// 13:54 in Riyadh on 9 November 2026.
final DateTime _now = DateTime.utc(2026, 11, 9, 10, 54);

TodayTask _dose(
  String time, {
  TodayTaskStatus status = TodayTaskStatus.late,
  int day = 9,
}) => TodayTask.medication(
  DoseOccurrence(
    planId: 'p',
    scheduleId: 's',
    scheduledOn: DateTime(2026, 11, day),
    time: time,
    name: 'تجريبي 2',
    strengthValue: 400,
    strengthUnit: StrengthUnit.milligram,
    dosageForm: DosageForm.capsule,
    doseValue: 1,
    doseUnit: DoseUnit.capsule,
  ),
  status,
);

void main() {
  final SimplifiedSnooze snooze = SimplifiedSnooze.of(
    _dose('13:30'),
    _now,
    const Duration(minutes: 15),
  );

  test('a snooze comes again after its delay', () {
    expect(snooze.until, DateTime.utc(2026, 11, 9, 11, 9));
    expect(snooze.isOver(_now), isFalse);
    expect(snooze.isOver(_now.add(const Duration(minutes: 15))), isTrue);
  });

  test('a snooze puts off its own task only, until it is recorded', () {
    expect(snooze.covers(_dose('13:30')), isTrue);
    expect(
      snooze.covers(_dose('13:30', status: TodayTaskStatus.done)),
      isFalse,
    );
    expect(snooze.covers(_dose('20:00')), isFalse);
    expect(snooze.covers(_dose('13:30', day: 10)), isFalse);
  });

  test('putting it off again moves the time, not the task', () {
    final SimplifiedSnooze again = snooze.again(
      _now.add(const Duration(minutes: 15)),
      const Duration(minutes: 15),
    );
    expect(again.until, DateTime.utc(2026, 11, 9, 11, 24));
    expect(again.covers(_dose('13:30')), isTrue);
  });

  test('a saved snooze reads back the same', () {
    expect(SimplifiedSnooze.fromJson(snooze.toJson()), snooze);
  });

  test('anything else read back is no snooze', () {
    expect(SimplifiedSnooze.fromJson(null), isNull);
    expect(SimplifiedSnooze.fromJson(<String, Object>{'kind': 'x'}), isNull);
    expect(
      SimplifiedSnooze.fromJson(<String, Object>{
        'kind': 'medication',
        'day': 'not a day',
        'time': '13:30',
        'until': '2026-11-09T11:09:00.000Z',
      }),
      isNull,
    );
  });
}
