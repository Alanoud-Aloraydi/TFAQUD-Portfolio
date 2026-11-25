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
  });
}
