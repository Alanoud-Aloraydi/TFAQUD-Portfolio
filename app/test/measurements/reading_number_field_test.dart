import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/measurements/presentation/widgets/reading_number_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a blood pressure reads as the monitor shows it: the upper '
      'number on top, each name at the start of its line', (tester) async {
    final TextEditingController upper = TextEditingController();
    final TextEditingController lower = TextEditingController();
    addTearDown(upper.dispose);
    addTearDown(lower.dispose);
    await tester.pumpWidget(
      MaterialApp(
        // The rows read the app's colours, as on every page.
        theme: AppTheme.lightTheme,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Column(
              children: <Widget>[
                ReadingNumberField(
                  label: 'الانقباضي',
                  unit: 'ملم زئبق',
                  controller: upper,
                  onChanged: () {},
                  last: false,
                ),
                ReadingNumberField(
                  label: 'الانبساطي',
                  unit: 'ملم زئبق',
                  controller: lower,
                  onChanged: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final Finder boxes = find.byType(TextField);
    final Rect top = tester.getRect(boxes.at(0));
    final Rect bottom = tester.getRect(boxes.at(1));
    expect(top.bottom, lessThanOrEqualTo(bottom.top));
    // On an Arabic page the name is on the right, the box on the left.
    final Rect name = tester.getRect(find.text('الانقباضي'));
    expect(name.left, greaterThan(top.right));

    await tester.enterText(boxes.at(0), '١٢٠');
    expect(upper.text, '120');
  });
}
