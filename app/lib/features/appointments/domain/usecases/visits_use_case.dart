import 'dart:typed_data';

import 'package:app/features/appointments/domain/entities/visit_paper.dart';
import 'package:app/features/appointments/domain/repositories/visits_repository.dart';

/// The visit-paper reads and writes the application is allowed to make.
class VisitsUseCase {
  VisitsUseCase(this._repository);

  final VisitsRepository _repository;

  Future<VisitPaper?> get(String circleId, String id) =>
      _repository.get(circleId, id);

  Future<VisitPaper> save(String circleId, String id, VisitPaperDraft draft) =>
      _repository.save(circleId, id, draft);

  Future<Uint8List> audio(String circleId, String id) =>
      _repository.audio(circleId, id);

  Future<VisitPaper> saveAudio(String circleId, String id, Uint8List bytes) =>
      _repository.saveAudio(circleId, id, bytes);

  Future<VisitPaper> removeAudio(String circleId, String id) =>
      _repository.removeAudio(circleId, id);
}
