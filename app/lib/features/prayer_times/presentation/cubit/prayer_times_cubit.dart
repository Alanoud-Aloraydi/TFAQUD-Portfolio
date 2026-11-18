import 'package:app/features/prayer_times/domain/use_cases/prayer_times_use_case.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_loading.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_midnight.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_scope.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Loads the patient's today's prayer times for a circle, and again at the
/// patient's midnight. [clock] gives the current instant, so tests control
/// the day.
class PrayerTimesCubit extends Cubit<PrayerTimesState>
    with PrayerTimesScope, PrayerTimesMidnight, PrayerTimesLoading {
  PrayerTimesCubit(this.repository, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now,
      super(const PrayerTimesState());

  @override
  final PrayerTimesUseCase repository;
  @override
  final DateTime Function() clock;

  @override
  Future<void> close() async {
    midnight?.cancel();
    return super.close();
  }
}
