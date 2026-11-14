import 'dart:typed_data';

import 'package:app/features/appointments/domain/visit_paper.dart';

/// The paper of one visit: what was said, and the voice note with it.
abstract class VisitsRepositoryDomain {
  Future<VisitPaper?> get(String circleId, String id);

  Future<VisitPaper> save(String circleId, String id, VisitPaperDraft draft);

  Future<Uint8List> audio(String circleId, String id);

  Future<VisitPaper> saveAudio(String circleId, String id, Uint8List bytes);

  Future<VisitPaper> removeAudio(String circleId, String id);
}
