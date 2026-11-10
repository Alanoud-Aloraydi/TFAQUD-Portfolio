import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/simplified_mode/data/simplified_preferences.dart';
import 'package:app/features/simplified_mode/data/simplified_voice.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_speech_rate.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_settings_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_controls.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/simplified_fakes.dart';
import '../support/widget_harness.dart';

const Object _card = #card;
const Object _button = #button;

/// A screen of two parts: a card with its speaker beside it, and a button
/// without one.
const List<SpokenPart> _parts = <SpokenPart>[
  (id: _card, text: 'موعدك بكرة'),
  (id: _button, text: 'رجوع'),
];

void main() {
  group('SimplifiedListen', () {
    late FakeSimplifiedVoice voice;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await EasyLocalization.ensureInitialized();
    });

    setUp(() {
      voice = FakeSimplifiedVoice();
      GetIt.I.registerSingleton<SimplifiedVoice>(voice);
    });

    tearDown(() => GetIt.I.unregister<SimplifiedVoice>());

    /// [screen] with the settings saved as [saved].
    Future<void> open(
      WidgetTester tester,
      Widget screen, {
      Map<String, Object> saved = const <String, Object>{},
    }) async {
      SharedPreferences.setMockInitialValues(saved);
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const <Locale>[Locale('ar')],
          startLocale: const Locale('ar'),
          path: 'assets/translations',
          assetLoader: const TestTranslations(),
          child: Builder(
            builder: (context) => MaterialApp(
              theme: AppTheme.lightTheme,
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              home: BlocProvider<SimplifiedSettingsCubit>(
                create: (_) =>
                    SimplifiedSettingsCubit(SimplifiedPreferences())..load(),
                child: Scaffold(
                  body: ListenScope(parts: _parts, child: screen),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    const Widget twoParts = Column(
      children: <Widget>[
        ListenTarget(
          id: _card,
          speaker: ListenSpeaker.beside,
          child: Text('موعدك بكرة'),
        ),
        ListenTarget(id: _button, child: Text('رجوع')),
      ],
    );

    final Finder speaker = find.byIcon(CupertinoIcons.speaker_2_fill);

    group('a card speaker', () {
      testWidgets('reads its own part alone, at the usual pace', (
        tester,
      ) async {
        await open(tester, twoParts);

        expect(speaker, findsOneWidget);
        await tester.tap(speaker);
        await tester.pumpAndSettle();

        expect(voice.said, hasLength(1));
        final (List<SpokenPart> parts, double rate) = voice.said.single;
        expect(parts.map((part) => part.id), <Object>[_card]);
        expect(rate, SimplifiedSpeechRate.normal.rate);
      });

      testWidgets('reads at the pace chosen in «حسابي»', (tester) async {
        await open(
          tester,
          twoParts,
          saved: <String, Object>{'simplified_speech_rate': 'slow'},
        );

        await tester.tap(speaker);
        await tester.pumpAndSettle();

        expect(voice.said.single.$2, SimplifiedSpeechRate.slow.rate);
      });

      testWidgets('becomes «إيقاف» while its part is read, and stops it', (
        tester,
      ) async {
        await open(tester, twoParts);

        voice.reading.value = _card;
        await tester.pumpAndSettle();
        expect(speaker, findsNothing);
        await tester.tap(find.byIcon(CupertinoIcons.stop_fill));
        await tester.pumpAndSettle();

        expect(voice.stops, 1);
        expect(voice.said, isEmpty);
      });

      testWidgets('is hidden when reading is turned off', (tester) async {
        await open(
          tester,
          twoParts,
          saved: <String, Object>{'simplified_voice_enabled': false},
        );

        expect(speaker, findsNothing);
        expect(find.text('موعدك بكرة'), findsOneWidget);
      });
    });

    testWidgets('«استماع» reads the whole screen, in its order', (
      tester,
    ) async {
      await open(tester, const ListenButton());

      await tester.tap(find.text('simplified_mode.listen'.tr()));
      await tester.pumpAndSettle();

      expect(voice.said.single.$1.map((part) => part.id), <Object>[
        _card,
        _button,
      ]);
    });

    group('a reminder', () {
      const Widget reminder = ReadOnOpen(child: Text('موعدك بكرة'));

      testWidgets('reads itself once as it opens, and stops when it closes', (
        tester,
      ) async {
        await open(tester, reminder);
        await tester.pumpAndSettle();

        expect(voice.said, hasLength(1));
        expect(voice.said.single.$1.map((part) => part.id), <Object>[
          _card,
          _button,
        ]);

        await tester.pumpWidget(const SizedBox());
        expect(voice.stops, 1);
      });

      testWidgets('stays silent when its reading is turned off', (
        tester,
      ) async {
        await open(
          tester,
          reminder,
          saved: <String, Object>{'simplified_auto_read': false},
        );

        expect(voice.said, isEmpty);
      });

      testWidgets('stays silent when all reading is turned off', (
        tester,
      ) async {
        await open(
          tester,
          reminder,
          saved: <String, Object>{'simplified_voice_enabled': false},
        );

        expect(voice.said, isEmpty);
      });
    });

    group('the reading settings', () {
      test('start at the usual pace, with reminders read aloud', () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final SimplifiedSettingsCubit cubit = SimplifiedSettingsCubit(
          SimplifiedPreferences(),
        );
        addTearDown(cubit.close);

        final Future<SimplifiedSettingsState> loaded = cubit.whenLoaded();
        await cubit.load();

        expect((await loaded).speechRate, SimplifiedSpeechRate.normal);
        expect(cubit.state.autoRead, isTrue);
        expect(cubit.state.loaded, isTrue);
      });

      test('are kept for the next start', () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final SimplifiedSettingsCubit first = SimplifiedSettingsCubit(
          SimplifiedPreferences(),
        );
        await first.load();
        await first.setSpeechRate(SimplifiedSpeechRate.fast);
        await first.setAutoRead(false);
        await first.close();

        final SimplifiedSettingsCubit next = SimplifiedSettingsCubit(
          SimplifiedPreferences(),
        );
        addTearDown(next.close);
        await next.load();

        expect(next.state.speechRate, SimplifiedSpeechRate.fast);
        expect(next.state.autoRead, isFalse);
        expect(next.state.voiceEnabled, isTrue);
      });
    });
  });
}
