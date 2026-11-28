import 'dart:ui' show Size;

import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/simplified_mode/domain/usecases/simplified_mode_use_case.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_cubit.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_measure_screen.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_measure_scaffold.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

/// No readings yet; nothing else is asked of it before a save.
class _UseCase implements SimplifiedModeUseCase {
  @override
  Future<List<MeasurementReading>> recentReadings(
    String circleId,
    DateTime now, {
    int days = 7,
  }) async => const <MeasurementReading>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('«تسجيل قياس»', () {
    setUpAll(initTestLocalization);

    /// The screen as its route builds it: the cubit is made, and loaded,
    /// by the screen's first read of it.
    Future<void> open(WidgetTester tester) => pumpArabic(
      tester,
      home: BlocProvider<SimplifiedMeasurementCubit>(
        create: (_) => SimplifiedMeasurementCubit(
          _UseCase(),
          'c-1',
          clock: () => noonInRiyadh,
        )..load(),
        child: const SimplifiedMeasureScreen(),
      ),
    );

    testWidgets('a free reading («سجّل قياسًا») opens on the form, ready to '
        'type, never «nothing to record»', (tester) async {
      await open(tester);

      expect(find.text('simplified_mode.no_target'.tr()), findsNothing);
      expect(find.text('simplified_mode.save_reading'.tr()), findsOneWidget);
      expect(find.byType(SimplifiedMeasureKeypad), findsOneWidget);
    });

    testWidgets("the keypad's delete key is the phone's ⌫, not an arrow", (
      tester,
    ) async {
      await open(tester);

      expect(find.byIcon(CupertinoIcons.delete_left), findsOneWidget);
    });

    testWidgets('a blood pressure out of range says the blood pressure '
        'ranges only, not the sugar', (tester) async {
      await open(tester);
      // A screen tall enough for the whole form: a finder does not see a
      // card the list has scrolled away from.
      tester.view.physicalSize = const Size(400, 2400);
      await tester.pump();
      Future<void> tap(Finder finder) async {
        await tester.tap(finder);
        await tester.pump();
      }

      for (final String digit in <String>['1', '2', '4']) {
        await tap(find.text(digit));
      }
      await tap(find.text('simplified_mode.lower'.tr()));
      for (final String digit in <String>['8', '0', '0']) {
        await tap(find.text(digit));
      }
      await tap(find.text('simplified_mode.save_reading'.tr()));

      expect(find.text('measurements.invalid_pressure'.tr()), findsOneWidget);
      expect(find.text('measurements.invalid_glucose'.tr()), findsNothing);
    });
  });
}
