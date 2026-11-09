import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_cubit.dart';
import 'package:app/features/circles/presentation/pages/medical_file_edit_screen.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_text_scale.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/circles_fakes.dart';

class _Translations extends AssetLoader {
  const _Translations();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(File('$path/ar.json').readAsStringSync())
          as Map<String, dynamic>;
}

const String _filePage = '/file';
const String _editPage = '/edit';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  /// The edit page built by [screen] at [_editPage], over a medical file
  /// page and a circle tab; the app opens on [start].
  Future<GoRouter> open(
    WidgetTester tester, {
    required MedicalFileEditScreen screen,
    String start = _filePage,
  }) async {
    tester.view.physicalSize = const Size(600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final GoRouter router = GoRouter(
      initialLocation: start,
      routes: <RouteBase>[
        GoRoute(
          path: _filePage,
          builder: (context, state) => const Scaffold(body: Text('file page')),
        ),
        GoRoute(
          path: Routes.circle,
          builder: (context, state) => const Scaffold(body: Text('circle tab')),
        ),
        GoRoute(
          path: _editPage,
          builder: (context, state) => BlocProvider(
            create: (context) => MedicalFileEditCubit(
              CirclesUseCase(CirclesFakeRepository()),
              'circle-1',
            )..start(CirclesFakeRepository.nouraFile),
            child: screen,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ar')],
        startLocale: const Locale('ar'),
        path: 'assets/translations',
        assetLoader: const _Translations(),
        child: Builder(
          builder: (context) => MaterialApp.router(
            theme: AppTheme.lightTheme,
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('circles.file_save'.tr()));
    await tester.pumpAndSettle();
  }

  group('after «حفظ» the edit page', () {
    testWidgets('goes to the circle tab by default, as the detailed mode '
        'does', (tester) async {
      final GoRouter router = await open(
        tester,
        screen: const MedicalFileEditScreen(),
      );
      unawaited(router.push<void>(_editPage));
      await tester.pumpAndSettle();

      await save(tester);

      expect(find.byType(MedicalFileEditScreen), findsNothing);
      expect(find.text('circle tab'), findsOneWidget);
    });

    testWidgets('without a destination returns to the page under it, as '
        'the simplified mode needs', (tester) async {
      final GoRouter router = await open(
        tester,
        screen: const MedicalFileEditScreen(savedTo: null, closeTo: _filePage),
      );
      unawaited(router.push<void>(_editPage));
      await tester.pumpAndSettle();

      await save(tester);

      expect(find.byType(MedicalFileEditScreen), findsNothing);
      expect(find.text('file page'), findsOneWidget);
      expect(find.text('circle tab'), findsNothing);
    });

    testWidgets('without a page under it goes to the medical file it was '
        'given', (tester) async {
      await open(
        tester,
        screen: const MedicalFileEditScreen(savedTo: null, closeTo: _filePage),
        start: _editPage,
      );

      await save(tester);

      expect(find.byType(MedicalFileEditScreen), findsNothing);
      expect(find.text('file page'), findsOneWidget);
    });
  });

  testWidgets('a detailed page shown in the simplified mode has its body at '
      'the simplified body size', (tester) async {
    late TextScaler scaler;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.15)),
          child: SimplifiedDetailScale(
            child: Builder(
              builder: (context) {
                scaler = MediaQuery.textScalerOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );

    final double detailedBody =
        AppTheme.lightTheme.textTheme.bodyLarge!.fontSize!;
    expect(
      scaler.scale(detailedBody),
      moreOrLessEquals(SimplifiedStyle.body * 1.15),
    );
  });
}
