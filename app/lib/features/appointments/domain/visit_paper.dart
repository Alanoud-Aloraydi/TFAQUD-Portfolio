import 'package:equatable/equatable.dart';

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
