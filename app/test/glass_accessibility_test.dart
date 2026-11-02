import 'package:app/core/services/app_accessibility.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/theme/materials/glass_preferences.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    AppAccessibility.reduceTransparency.value = false;
    AppAccessibility.channel.setMethodCallHandler(null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AppAccessibility.channel, null);
  });

  test(
    'reads the initial iOS preference and responds to native changes',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            AppAccessibility.channel,
            (call) async => true,
          );
      await AppAccessibility.initialize();
      expect(AppAccessibility.reduceTransparency.value, isTrue);
      ServicesBinding.instance.channelBuffers.push(
        'tafaqod/accessibility',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('reduceTransparencyChanged', false),
        ),
        (_) {},
      );
      await Future<void>.delayed(Duration.zero);
      expect(AppAccessibility.reduceTransparency.value, isFalse);
    },
  );

  for (final highContrast in [false, true]) {
    testWidgets(
      'glass responds to transparency changes: contrast=$highContrast',
      (tester) async {
        Future<void> show(bool reduced) => tester.pumpWidget(
          MaterialApp(
            theme: highContrast
                ? AppTheme.highContrastTheme
                : AppTheme.lightTheme,
            home: MediaQuery(
              data: MediaQueryData(highContrast: highContrast),
              child: GlassPreferences(
                reduceTransparency: reduced,
                child: const GlassSurface(
                  borderRadius: BorderRadius.all(Radius.circular(22)),
                  child: SizedBox(width: 100, height: 44),
                ),
              ),
            ),
          ),
        );
        await show(false);
        expect(
          find.byType(BackdropFilter),
          highContrast ? findsNothing : findsOneWidget,
        );
        await show(true);
        expect(find.byType(BackdropFilter), findsNothing);
        await show(false);
        expect(
          find.byType(BackdropFilter),
          highContrast ? findsNothing : findsOneWidget,
        );
      },
    );
  }
}
