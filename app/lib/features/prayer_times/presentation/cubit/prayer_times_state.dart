import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:equatable/equatable.dart';

enum PrayerTimesStatus { loading, ready, failure }

/// The patient's prayer times for today, as the screen shows them.
class PrayerTimesState extends Equatable {
  const PrayerTimesState({
    this.status = PrayerTimesStatus.loading,
    this.day,
    this.messageKey,
  });

  final PrayerTimesStatus status;
  final PrayerDay? day;
  final String? messageKey;

  @override
  List<Object?> get props => [status, day, messageKey];
}
