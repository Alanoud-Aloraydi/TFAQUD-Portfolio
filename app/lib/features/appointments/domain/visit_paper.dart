import 'package:equatable/equatable.dart';

/// Stores the notes and recording attached to a visit.
class VisitPaper extends Equatable {
  const VisitPaper({
    required this.summary,
    required this.recommendations,
    required this.followUp,
    required this.hasAudio,
  });

  final String? summary;
  final String? recommendations;
  final String? followUp;
  final bool hasAudio;

  @override
  List<Object?> get props => [summary, recommendations, followUp, hasAudio];
}

/// Holds editable visit paper values before saving.
class VisitPaperDraft extends Equatable {
  const VisitPaperDraft({
    required this.summary,
    required this.recommendations,
    required this.followUp,
  });

  final String? summary;
  final String? recommendations;
  final String? followUp;

  @override
  List<Object?> get props => [summary, recommendations, followUp];
}
