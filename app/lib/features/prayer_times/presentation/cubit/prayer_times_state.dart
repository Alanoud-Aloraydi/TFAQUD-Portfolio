import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:equatable/equatable.dart';

/// Defines the supported prayer times status values.
enum PrayerTimesStatus { loading, ready, failure }

/// Holds the prayer times presentation state.
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
