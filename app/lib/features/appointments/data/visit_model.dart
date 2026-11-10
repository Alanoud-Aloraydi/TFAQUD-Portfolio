import 'package:app/features/appointments/domain/visit_paper.dart';

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
