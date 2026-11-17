import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/components/task_button_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the buttons under a task have no edge, as the pills beside them', () {
    for (final TaskButtonRole role in TaskButtonRole.values) {
      expect(
        role.style.side?.resolve(<WidgetState>{}),
        BorderSide.none,
        reason: role.name,
      );
    }
  });

  test('the answer has the colours of «إضافة عضو», every main action', () {
    expect(TaskButtonRole.answer.fill, AppSemanticColors.actionPrimary);
    expect(TaskButtonRole.answer.ink, AppSemanticColors.onActionPrimary);
  });

  test(
    '«ذكّرني لاحقًا» shows on the cream of a late dose and reads clearly',
    () {
      double luminance(Color c) => c.computeLuminance();
      double contrast(Color a, Color b) {
        final double x = luminance(a);
        final double y = luminance(b);
        return (x > y ? x + 0.05 : y + 0.05) / (x > y ? y + 0.05 : x + 0.05);
      }

      final TaskButtonRole later = TaskButtonRole.later;
      // Its fill stands apart from the cream card it sits on.
      const Color card = AppSemanticColors.surfaceAttentionGroup;
      expect(contrast(later.fill, card), greaterThan(1.3));
      expect(contrast(later.ink, later.fill), greaterThanOrEqualTo(7));
    },
  );
}
