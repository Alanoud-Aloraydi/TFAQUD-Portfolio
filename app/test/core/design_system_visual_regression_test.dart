import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/feedback/status_pill.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/features/onboarding/presentation/widgets/choice_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    final font = FontLoader('IBMPlexSansArabic')
      ..addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'));
    await font.load();
  });

  for (final highContrast in [false, true]) {
    for (final scale in [1.0, 1.4]) {
      final name =
          '${highContrast ? 'contrast' : 'light'}_${scale == 1 ? 'default' : 'large'}';
      testWidgets('shared components preserve their RTL appearance: $name', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(430, 1300);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: highContrast
                ? AppTheme.highContrastTheme
                : AppTheme.lightTheme,
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(430, 1300),
                highContrast: highContrast,
                textScaler: TextScaler.linear(scale),
              ),
              child: const Directionality(
                textDirection: TextDirection.rtl,
                child: RepaintBoundary(
                  key: ValueKey('showcase'),
                  child: _Showcase(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('showcase')),
          matchesGoldenFile('goldens/design_system/$name.png'),
        );
      });
    }
  }
}

class _Showcase extends StatelessWidget {
  const _Showcase();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'متابعة الرعاية',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'تفاصيل المريض',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            PillButton(label: 'حفظ التغييرات', onPressed: () {}),
            const PillButton(label: 'غير متاح', onPressed: null),
            OutlinedButton(onPressed: () {}, child: const Text('إجراء آخر')),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'الاسم',
                hintText: 'اسم المريض',
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'قيمة',
                errorText: 'تعذر حفظ القيمة',
              ),
            ),
            const SizedBox(height: 16),
            InsetGroup(
              header: 'المعلومات',
              children: [
                ListTile(
                  title: const Text('المريض'),
                  trailing: Text(
                    'اسم',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ChoiceCard(
              icon: Icons.person_outline,
              title: 'اختيار',
              hint: 'وصف الاختيار',
              selected: true,
              onTap: () {},
            ),
            const SizedBox(height: 16),
            StatusPill(
              text: 'حالة مسجلة',
              background: scheme.surface,
              foreground: scheme.onSurface,
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(height: 16),
            GlassSegmentedControl<int>(
              segments: const {0: 'الحالية', 1: 'السابقة'},
              selected: 0,
              onChanged: (_) {},
            ),
            const SizedBox(height: 16),
            GlassSurface(
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'دائرة الرعاية',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
