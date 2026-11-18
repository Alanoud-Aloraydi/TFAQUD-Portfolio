import 'package:app/features/simplified_mode/domain/entities/today_task.dart';

/// What makes two [TodayTask]s equal: every field, in the order the
/// class declares them.
List<Object?> todayTaskProps(TodayTask task) => <Object?>[
  task.kind,
  task.day,
  task.time,
  task.status,
  task.dose,
  task.measurement,
  task.appointment,
];
