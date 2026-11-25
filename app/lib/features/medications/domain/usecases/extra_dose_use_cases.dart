import 'package:app/core/errors/failure.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';
import 'package:app/features/medications/domain/repositories/medications_repository.dart';
import 'package:multiple_result/multiple_result.dart';

/// «سجّل جرعة الآن» in [MedicationsUseCase]. An extra dose changes no
/// reminder, so it is not a change of the medicines.
mixin ExtraDoseUseCases {
  MedicationsRepository get repository;

  Future<Result<ExtraDose, Failure>> recordExtraDose(
    String circleId,
    ExtraDoseDraft draft,
  ) => repository.recordExtraDose(circleId, draft);

  Future<Result<List<ExtraDose>, Failure>> getExtraDoses(
    String circleId,
    DateTime from,
    DateTime to, {
    String? planId,
  }) => repository.getExtraDoses(circleId, from, to, planId: planId);
}
