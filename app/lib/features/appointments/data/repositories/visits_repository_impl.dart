import 'dart:typed_data';

import 'package:app/features/appointments/data/datasources/visit_remote_data_source.dart';
import 'package:app/features/appointments/domain/entities/visit_paper.dart';
import 'package:app/features/appointments/domain/repositories/visits_repository.dart';

/// The server owns the visit papers and their voice notes.
class VisitsRepositoryImpl implements VisitsRepository {
  VisitsRepositoryImpl(this._remote);

  final VisitRemoteDataSource _remote;

  @override
  Future<VisitPaper?> get(String circleId, String id) async =>
      VisitModel.fromJson((await _remote.get(circleId, id))['visit']);

  @override
  Future<VisitPaper> save(
    String circleId,
    String id,
    VisitPaperDraft draft,
  ) async => VisitModel.fromJson(
    (await _remote.save(circleId, id, VisitModel.toJson(draft)))['visit'],
  )!;

  @override
  Future<Uint8List> audio(String circleId, String id) =>
      _remote.audio(circleId, id);

  @override
  Future<VisitPaper> saveAudio(
    String circleId,
    String id,
    Uint8List bytes,
  ) async => VisitModel.fromJson(
    (await _remote.saveAudio(circleId, id, bytes))['visit'],
  )!;

  @override
  Future<VisitPaper> removeAudio(String circleId, String id) async =>
      VisitModel.fromJson((await _remote.removeAudio(circleId, id))['visit'])!;
}

/// Maps visit data between the API and app.
class VisitModel {
  const VisitModel._();

  static VisitPaper? fromJson(Object? value) {
    if (value == null) return null;
    final json = value as Map<String, dynamic>;
    return VisitPaper(
      summary: json['summary'] as String?,
      recommendations: json['recommendations'] as String?,
      followUp: json['follow_up'] as String?,
      hasAudio: json['has_audio'] as bool,
    );
  }

  static Map<String, dynamic> toJson(VisitPaperDraft draft) => {
    'summary': draft.summary,
    'recommendations': draft.recommendations,
    'follow_up': draft.followUp,
  };
}
