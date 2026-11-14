import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_basic_fields.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

class _Host extends StatefulWidget {
  const _Host(this.data);

  final MedicationFormData data;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SingleChildScrollView(
      child: MedicationInstructionsGroup(
        data: widget.data,
        onChanged: () => setState(() {}),
      ),
    ),
  );
}

String _choice(String code) => 'medications.instruction_choice.$code'.tr();

void main() {
  setUpAll(initTestLocalization);

  testWidgets('the text field shows only once «أخرى» is chosen', (
    tester,
  ) async {
    final MedicationFormData data = MedicationFormData(
      null,
      today: DateTime(2026, 11, 12),
    );
    addTearDown(data.dispose);
    await pumpArabic(tester, home: _Host(data));
    final Finder field = find.text('medications.instructions_other'.tr());

    expect(field, findsNothing);
    await tester.tap(find.widgetWithText(FilterChip, _choice('with_meal')));
    await tester.pumpAndSettle();
    expect(data.instructions.text, _choice('with_meal'));
    expect(field, findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, _choice('other')));
    await tester.pumpAndSettle();
    expect(field, findsOneWidget);
    // The person's own words start empty.
    expect(data.instructions.text, isEmpty);

    await tester.tap(find.widgetWithText(FilterChip, _choice('none')));
    await tester.pumpAndSettle();
    expect(field, findsNothing);
    expect(data.instructions.text, isEmpty);
  });
}
