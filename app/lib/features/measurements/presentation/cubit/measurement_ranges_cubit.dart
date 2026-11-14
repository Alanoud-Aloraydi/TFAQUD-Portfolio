import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

/// Holds the normal ranges of one patient while they load.
class MeasurementRangesState extends Equatable {
  const MeasurementRangesState({
    this.loading = true,
    this.ranges,
    this.errorKey,
  });

  final bool loading;

  /// Null until read, or when reading failed.
  final NormalRanges? ranges;
  final String? errorKey;

  @override
  List<Object?> get props => [loading, ranges, errorKey];
}

/// The normal ranges of one circle's patient, for «المعدل الطبيعي». Saving a
/// reading never waits for them: the server judges it either way.
class MeasurementRangesCubit extends Cubit<MeasurementRangesState> {
  MeasurementRangesCubit(this._repository, [this._circles])
    : super(const MeasurementRangesState());

  final MeasurementRepository _repository;

  /// The medical file, for [setCondition]; null where the condition is
  /// only read.
  final CirclesUseCase? _circles;

  /// Reads [circleId]'s ranges; called again to retry after a failure.
  /// [quiet] keeps the ranges on screen while the new ones load.
  Future<void> load(String circleId, {bool quiet = false}) async {
    if (!quiet || state.ranges == null) emit(const MeasurementRangesState());
    try {
      final NormalRanges ranges = await _repository.ranges(circleId);
      if (!isClosed) {
        emit(MeasurementRangesState(loading: false, ranges: ranges));
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          MeasurementRangesState(
            loading: false,
            errorKey: FailureExceptions.getException(error).messageKey,
          ),
        );
      }
    }
  }

  /// Saves in [circleId]'s medical file whether the patient has [code]
  /// (`diabetes` or `hypertension`), the rest of the file as it is, then
  /// reads the ranges again: the condition picks them. Returns the error's
  /// key, or null once saved.
  Future<String?> setCondition(
    String circleId,
    String code, {
    required bool has,
  }) async {
    final CirclesUseCase? circles = _circles;
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
