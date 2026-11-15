import 'package:app/features/appointments/domain/visit_paper.dart';
import 'package:flutter/widgets.dart';

/// The three texts of «ورقة الزيارة» while they are filled in: each with
/// its heading's key, the most characters it holds, and its controller.
class VisitPaperTexts {
  VisitPaperTexts(VisitPaper? paper)
    : fields = <(String, int, TextEditingController)>[
        _field('appointments.visit_summary', 2000, paper?.summary),
        _field(
          'appointments.visit_recommendations',
          2000,
          paper?.recommendations,
        ),
        _field('appointments.visit_follow_up', 500, paper?.followUp),
      ];

  final List<(String, int, TextEditingController)> fields;

  static (String, int, TextEditingController) _field(
    String key,
    int limit,
    String? text,
  ) => (key, limit, TextEditingController(text: text));

  /// What «حفظ» sends.
  VisitPaperDraft get draft => VisitPaperDraft(
    summary: fields[0].$3.text,
    recommendations: fields[1].$3.text,
    followUp: fields[2].$3.text,
  );

  void dispose() {
    for (final (_, _, TextEditingController text) in fields) {
      text.dispose();
    }
  }
}
