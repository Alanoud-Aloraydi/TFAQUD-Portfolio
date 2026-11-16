import 'package:equatable/equatable.dart';

/// One planned reading time and its glucose «حالة القياس».
class MeasurementTime extends Equatable {
  const MeasurementTime({required this.time, this.measurementState});

  /// «HH:mm», the patient's wall clock.
  final String time;

  final String? measurementState;

  factory MeasurementTime.fromJson(Map<String, dynamic> json) =>
      MeasurementTime(
        time: json['time_of_day'] as String,
        measurementState: json['measurement_state'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'time_of_day': time,
    'measurement_state': measurementState,
  };

  @override
  List<Object?> get props => [time, measurementState];
}

/// Preserves one effective measurement schedule.
class MeasurementVersion extends Equatable {
  const MeasurementVersion({
    required this.id,
    required this.number,
    required this.effectiveFromOn,
    required this.time,
    required this.weekdays,
    required this.missedAfterMinutes,
    this.times = const <MeasurementTime>[],
  });

  final String id;
  final int number;
  final DateTime effectiveFromOn;

  /// The first reading time ([readingTimes] has them all).
  final String time;
  final List<int> weekdays;
  final int missedAfterMinutes;

  /// The reading times as the server listed them; [readingTimes] is what to
  /// use.
  final List<MeasurementTime> times;

  /// Every reading time of a day, earliest first; the first alone when a
  /// version was built without the list.
  List<MeasurementTime> get readingTimes =>
      times.isEmpty ? <MeasurementTime>[MeasurementTime(time: time)] : times;

  factory MeasurementVersion.fromJson(Map<String, dynamic> json) {
    final List<MeasurementTime> times = (json['times'] as List<dynamic>)
        .map((item) => MeasurementTime.fromJson(item as Map<String, dynamic>))
        .toList();
    return MeasurementVersion(
      id: json['id'] as String,
      number: json['version_number'] as int,
      effectiveFromOn: DateTime.parse(json['effective_from_on'] as String),
      time: times.first.time,
      weekdays: (json['weekdays'] as List<dynamic>).cast<int>(),
      missedAfterMinutes: json['missed_after_minutes'] as int,
      times: times,
    );
  }

  @override
  List<Object?> get props => [
    id,
    number,
    effectiveFromOn,
    time,
    weekdays,
    missedAfterMinutes,
    times,
  ];
}
