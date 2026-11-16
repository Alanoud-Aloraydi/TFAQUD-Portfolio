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
}
