import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

/// Saves a condition of the medical file from «المعدل الطبيعي», then reads
/// the ranges it picks.
mixin MeasurementRangeCondition on Cubit<MeasurementRangesState> {
  /// The medical file, for [setCondition]; null where the condition is
  /// only read.
  CirclesUseCase? get circles;

  /// Reads [circleId]'s ranges; [quiet] keeps the ranges on screen.
  Future<void> load(String circleId, {bool quiet = false});

  /// Saves in [circleId]'s medical file whether the patient has [code]
  /// (`diabetes` or `hypertension`), the rest of the file as it is, then
  /// reads the ranges again: the condition picks them. Returns the error's
  /// key, or null once saved.
  Future<String?> setCondition(
    String circleId,
    String code, {
    required bool has,
  }) async {
    final CirclesUseCase? circles = this.circles;
    if (circles == null) return 'error.unknown';
    // Read first, so the other conditions, the blood type and the
    // allergies go back exactly as they are.
    final Result<MedicalFile, Failure> read = await circles.getMedicalFile(
      circleId,
    );
    if (read.tryGetError() case final Failure failure) {
      return failure.messageKey;
    }
    final MedicalFile file = read.tryGetSuccess()!;
    final MedicalProfileDraft profile = MedicalProfileDraft(
      bloodType: file.profile.bloodType,
      conditions: ConditionsDraft.withCode(
        file.profile.conditions,
        code,
        has: has,
      ),
      allergies: file.profile.allergies,
    );
    final Result<MedicalProfileDraft, Failure> saved = await circles
        .updateMedicalProfile(circleId, profile);
    if (saved.tryGetError() case final Failure failure) {
      return failure.messageKey;
    }
    // The medical file page and the circle tab, if open, show it at once.
    circles.medicalFileSaved(
      circleId,
      file.copyWith(profile: saved.tryGetSuccess()),
    );
    if (!isClosed) await load(circleId, quiet: true);
    return null;
  }
}
