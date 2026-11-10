import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/forms/keyboard_dismiss.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InputBehavior', () {
    group('WesternDigitsFormatter', () {
      TextEditingValue format(String text, {bool decimal = false}) =>
          WesternDigitsFormatter(decimal: decimal).formatEditUpdate(
            TextEditingValue.empty,
            TextEditingValue(
              text: text,
              selection: TextSelection.collapsed(offset: text.length),
            ),
          );

      test('turns Arabic-Indic and Persian digits into 0-9', () {
        expect(format('٥٠١٢').text, '5012');
        expect(format('۵۰۱۲').text, '5012');
        expect(format('5٠1').text, '501');
      });

      test('keeps the cursor where it was', () {
        expect(
          format('٥٠٠').selection,
          const TextSelection.collapsed(offset: 3),
        );
      });

      test('a decimal field turns «٫» and a comma into a point', () {
        expect(format('٢٫٥', decimal: true).text, '2.5');
        expect(format('2,5', decimal: true).text, '2.5');
        // Not a decimal field: the separator stays as typed.
        expect(format('٢٫٥').text, '2٫5');
      });
    });

    testWidgets('a number row takes Arabic digits and keeps English ones', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: InsetGroup(
                children: <Widget>[
                  InsetTextRow(
                    label: 'التركيز',
                    controller: controller,
                    onChanged: (_) {},
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    // The medicine form keeps only 0-9 and the point.
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '٥٠٠٫٥');
      expect(controller.text, '500.5');
    });

    testWidgets('a touch outside the field closes the keyboard', (
      WidgetTester tester,
    ) async {
      final FocusNode focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        MaterialApp(
          builder: (BuildContext context, Widget? child) =>
              KeyboardDismissOnTap(child: child!),
          home: Scaffold(
            body: Column(
              children: <Widget>[
                TextField(focusNode: focus),
                const SizedBox(height: 200, child: Text('outside')),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(focus.hasFocus, isTrue);

      await tester.tap(find.text('outside'));
      await tester.pump();
      expect(focus.hasFocus, isFalse);
    });
  });
}
