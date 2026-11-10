import 'package:app/core/services/app_accessibility.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/theme/materials/glass_preferences.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:app/features/simplified_mode/data/simplified_voice.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_text_scale.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Android 14's non-linear text size: big text grows less than small text.
class _NonLinearScaler extends TextScaler {
  const _NonLinearScaler();

  @override
  double scale(double fontSize) => fontSize < 20 ? fontSize * 2 : fontSize + 20;

  @Deprecated('Use scale instead.')
  @override
  double get textScaleFactor => 2;
}

void main() {
  group('PlatformCompat', () {
    group('glass on Android', () {
      test('is opaque below Android 10 and glass from it on', () {
        expect(AppAccessibility.blurIsCostly(24), isTrue);
        expect(AppAccessibility.blurIsCostly(28), isTrue);
        expect(AppAccessibility.blurIsCostly(29), isFalse);
        expect(AppAccessibility.blurIsCostly(35), isFalse);
      });
    });

    group('glass sheet bottom inset', () {
      test('clears the navigation bar or home indicator', () {
        const MediaQueryData media = MediaQueryData(
          viewPadding: EdgeInsets.only(bottom: 48),
        );
        expect(glassSheetBottomInset(media), 48);
      });

      test('rises over the keyboard while it is open', () {
        const MediaQueryData media = MediaQueryData(
          viewPadding: EdgeInsets.only(bottom: 34),
          viewInsets: EdgeInsets.only(bottom: 300),
        );
        expect(glassSheetBottomInset(media), 300);
      });
    });

    group('ScaledOverPhone', () {
      test("keeps the phone's non-linear curve for big text", () {
        const ScaledOverPhone scaler = ScaledOverPhone(_NonLinearScaler(), 1.5);
        // 12 * 1.5 = 18 is small text: doubled.
        expect(scaler.scale(12), 36);
        // 28 * 1.5 = 42 is big text: +20, not 28 * 1.5 * 2 = 84.
        expect(scaler.scale(28), 62);
      });

      test('equals another with the same phone and factor', () {
        expect(
          const ScaledOverPhone(TextScaler.noScaling, 1.2),
          const ScaledOverPhone(TextScaler.noScaling, 1.2),
        );
      });
    });

    group('bestArabicVoice on Android', () {
      Map<String, String> voice(
        String name, {
        String quality = 'normal',
        String network = '0',
        String features = '',
      }) => <String, String>{
        'name': name,
        'locale': 'ar',
        'quality': quality,
        'network_required': network,
        'features': features,
      };

      test('leaves out a voice whose data is not downloaded', () {
        expect(
          bestArabicVoice(<Map<String, String>>[
            voice('missing', quality: 'very high', features: 'a\tnotInstalled'),
            voice('local'),
          ])?['name'],
          'local',
        );
      });

      test('leaves out a voice that speaks only online', () {
        expect(
          bestArabicVoice(<Map<String, String>>[
            voice('online', quality: 'very high', network: '1'),
          ]),
          isNull,
        );
      });

      test('takes a very high voice over a normal one', () {
        expect(
          bestArabicVoice(<Map<String, String>>[
            voice('normal'),
            voice('clear', quality: 'very high'),
          ])?['name'],
          'clear',
        );
      });
    });
  });

  group('GlassAccessibility', () {
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
  });
}
