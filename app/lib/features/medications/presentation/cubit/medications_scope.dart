import 'package:app/core/errors/failure.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

/// What a medicines cubit is pointed at, shared by everything it does: the
/// circle, the one medicine when it shows only one, and the revision that
/// tells a stale answer from the newest one.
mixin MedicationsScope on Cubit<MedicationsState> {
  /// The use case the cubit was made with.
  MedicationsUseCase get medications;

  /// The circle whose medicines are shown.
  String? circleId;

  /// The one medicine this cubit shows, or null for the whole list.
  String? planId;

  /// Whether this cubit read something, so it has something to keep fresh.
  bool reads = false;

  /// Counts the readings, so a slower one cannot overwrite a newer answer.
  int revision = 0;

  /// Sets the circle for a cubit that only saves (no list is read).
  void bind(String circleId) {
    this.circleId = circleId;
  }

  /// The medicines to show: the list, or just [planId] when it is given.
  Future<Result<List<MedicationPlan>, Failure>> readPlans(
    String circleId,
    String? planId,
  ) async {
    if (planId == null) return medications.getPlans(circleId);
    final result = await medications.getPlan(circleId, planId);
    final MedicationPlan? plan = result.tryGetSuccess();
    return plan == null ? Error(result.tryGetError()!) : Success([plan]);
  }
}
