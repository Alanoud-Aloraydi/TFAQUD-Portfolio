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
}
