import 'dart:typed_data';

import 'package:app/features/appointments/data/visit_model.dart';
import 'package:app/features/appointments/data/visit_remote_data_source.dart';
import 'package:app/features/appointments/domain/visit_paper.dart';

/// Provides visit data operations.
class VisitRepository {
  VisitRepository(this._remote);

  final VisitRemoteDataSource _remote;

  Future<VisitPaper?> get(String circleId, String id) async =>
      VisitModel.fromJson((await _remote.get(circleId, id))['visit']);

  Future<VisitPaper> save(
    String circleId,
    String id,
    VisitPaperDraft draft,
  ) async => VisitModel.fromJson(
    (await _remote.save(circleId, id, VisitModel.toJson(draft)))['visit'],
  )!;

  Future<Uint8List> audio(String circleId, String id) =>
      _remote.audio(circleId, id);

  Future<VisitPaper> saveAudio(
    String circleId,
    String id,
    Uint8List bytes,
  ) async => VisitModel.fromJson(
    (await _remote.saveAudio(circleId, id, bytes))['visit'],
  )!;

  Future<VisitPaper> removeAudio(String circleId, String id) async =>
      VisitModel.fromJson((await _remote.removeAudio(circleId, id))['visit'])!;
}
