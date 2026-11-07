import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/dose_reminders.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_home_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Loads today's one task (due, or missed if nothing is due) and the
/// circle's members for the simplified home screen. Composes the existing
/// medication, measurement, and circle data instead of its own endpoint.
@injectable
class SimplifiedHomeCubit extends Cubit<SimplifiedHomeState> {
  SimplifiedHomeCubit(
    this._home,
    this._medications,
    this._measurements,
    this._circles,
    this._doseReminders,
  ) : super(const SimplifiedHomeState());

  final HomeUseCase _home;
  final MedicationsUseCase _medications;
  final MeasurementRepository _measurements;
  final CirclesUseCase _circles;
  final DoseReminders _doseReminders;

  Future<void> load() async {
    emit(const SimplifiedHomeState(status: SimplifiedHomeStatus.loading));
    final homeResult = await _home.getHome();
    if (isClosed) return;
    if (homeResult.isError() || homeResult.tryGetSuccess()!.circles.isEmpty) {
      emit(const SimplifiedHomeState(status: SimplifiedHomeStatus.error));
      return;
    }
    final home = homeResult.tryGetSuccess()!;
    final String circleId = home.circles.first.id;
    final DateTime today = riyadhToday();

    List<MeasurementOccurrence> measurementTasks = const [];
    try {
      measurementTasks = await _measurements.occurrences(
        circleId,
        today,
        today,
      );
    } catch (_) {
      // A measurement read failure never blocks the dose part of the
      // screen; it only means no measurement task can be shown today.
    }
    if (isClosed) return;

    final doseResult = await _medications.getOccurrences(
      circleId,
      today,
      today,
    );
    if (isClosed) return;
    final List<DoseOccurrence> doses =
        doseResult.tryGetSuccess() ?? const <DoseOccurrence>[];

    final overviewResult = await _circles.getCircleOverview(circleId);
    if (isClosed) return;

    final SimplifiedHomeTask? due = _firstDue(doses, measurementTasks);
    final SimplifiedHomeTask? missed = due == null
        ? _firstMissed(doses, measurementTasks)
        : null;
    emit(
      SimplifiedHomeState(
        status: due != null
            ? SimplifiedHomeStatus.due
            : missed != null
            ? SimplifiedHomeStatus.missed
            : SimplifiedHomeStatus.done,
        greetingName: home.displayName,
        greetingIsEvening: riyadhNow().hour >= 12,
        task: due ?? missed,
        members: overviewResult.tryGetSuccess()?.members ?? const [],
        circleId: circleId,
      ),
    );
  }

  /// Records the current dose task as taken, now. Returns whether it
  /// saved; false for a measurement task or when nothing is due.
  Future<bool> takeDose() async {
    final String? circleId = state.circleId;
    final DoseOccurrence? dose = state.task?.doseOccurrence;
    if (circleId == null || dose == null) return false;
    final result = await _medications.recordDose(
      circleId,
      dose,
      DoseRecordDraft(outcome: DoseOutcome.taken, takenAt: DateTime.now()),
    );
    if (isClosed) return false;
    if (result.isError()) return false;
    await _doseReminders.cancelSnooze();
    if (!isClosed) await load();
    return true;
  }

  /// Asks for the current dose's own reminder again [after] from now, so
  /// the person is reminded later instead of now.
  Future<void> snoozeDose(Duration after) async {
    final String? circleId = state.circleId;
    final DoseOccurrence? dose = state.task?.doseOccurrence;
    if (circleId == null || dose == null) return;
    await _doseReminders.snooze(
      circleId: circleId,
      title: 'simplified_mode.due_title'.tr(args: [dose.name]),
      body: 'simplified_mode.due_time'.tr(args: [dose.time]),
      after: after,
    );
  }

  SimplifiedHomeTask? _firstDue(
    List<DoseOccurrence> doses,
    List<MeasurementOccurrence> measurements,
  ) {
    for (final dose in doses) {
      if (dose.record == null &&
          (dose.timingState == DoseTimingState.due ||
              dose.timingState == DoseTimingState.late)) {
        return SimplifiedHomeTask.medication(dose);
      }
    }
    for (final item in measurements) {
      if (item.record == null && item.status == MeasurementStatus.due) {
        return SimplifiedHomeTask.measurement(item);
      }
    }
    return null;
  }

  SimplifiedHomeTask? _firstMissed(
    List<DoseOccurrence> doses,
    List<MeasurementOccurrence> measurements,
  ) {
    for (final dose in doses) {
      if (dose.record == null && dose.timingState == DoseTimingState.missed) {
        return SimplifiedHomeTask.medication(dose);
      }
    }
    for (final item in measurements) {
      if (item.record == null && item.status == MeasurementStatus.missed) {
        return SimplifiedHomeTask.measurement(item);
      }
    }
    return null;
  }
}
