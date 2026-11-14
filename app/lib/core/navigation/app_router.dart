import 'dart:async';

import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/navigation/fading_branches.dart';
import 'package:app/core/services/shown_circle_clock.dart';
import 'package:app/core/services/signed_out.dart';
import 'package:app/core/services/token_storage.dart';
import 'package:app/dev/component_gallery.dart';
import 'package:app/features/account/domain/use_cases/profile_use_case.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/pages/account_edit_screen.dart';
import 'package:app/features/account/presentation/pages/account_screen.dart';
import 'package:app/features/appointments/domain/services/visit_audio.dart';
import 'package:app/features/appointments/domain/use_cases/appointments_use_case.dart';
import 'package:app/features/appointments/domain/use_cases/visits_use_case.dart';
import 'package:app/features/appointments/presentation/cubit/appointment_companions_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:app/features/appointments/presentation/pages/appointment_form_page.dart';
import 'package:app/features/appointments/presentation/pages/visit_page.dart';
import 'package:app/features/auth/domain/repositories/welcome_memory.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:app/features/auth/presentation/cubit/splash_cubit.dart';
import 'package:app/features/auth/presentation/pages/auth_feature_screen.dart';
import 'package:app/features/auth/presentation/pages/code_screen.dart';
import 'package:app/features/auth/presentation/pages/phone_screen.dart';
import 'package:app/features/auth/presentation/pages/splash_screen.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/cubit/emergency_card_cubit.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_cubit.dart';
import 'package:app/features/circles/presentation/cubit/request_reply_cubit.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_cubit.dart';
import 'package:app/features/circles/presentation/pages/approved_circle_basics_screen.dart';
import 'package:app/features/circles/presentation/pages/circle_tab_screen.dart';
import 'package:app/features/circles/presentation/pages/emergency_card_screen.dart';
import 'package:app/features/circles/presentation/pages/medical_file_edit_screen.dart';
import 'package:app/features/circles/presentation/pages/medical_file_screen.dart';
import 'package:app/features/circles/presentation/pages/notifications_screen.dart';
import 'package:app/features/circles/presentation/pages/patient_circle_basics_screen.dart';
import 'package:app/features/circles/presentation/pages/request_patient_screen.dart';
import 'package:app/features/circles/presentation/pages/request_reply_screen.dart';
import 'package:app/features/circles/presentation/pages/self_circle_basics_screen.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/pages/home_feature_screen.dart';
import 'package:app/features/home/presentation/pages/plan_page.dart';
import 'package:app/features/home/presentation/pages/record_page.dart';
import 'package:app/features/home/presentation/pages/today_page.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_cubit.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_page.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/pages/medication_details_page.dart';
import 'package:app/features/medications/presentation/pages/medication_form_page.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/pages/profile_step_screen.dart';
import 'package:app/features/onboarding/presentation/pages/start_screen.dart';
import 'package:app/features/prayer_times/domain/use_cases/prayer_times_use_case.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/reminder_payload.dart';
import 'package:app/features/simplified_mode/domain/repositories/simplified_settings_store.dart';
import 'package:app/features/simplified_mode/domain/use_cases/simplified_mode_use_case.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_measurement_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_cubit.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_settings_cubit.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_account_screen.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_done_screen.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_measure_screen.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_medical_file_screen.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_mode_feature_screen.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_reminder_screen.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_schedule_screen.dart';
import 'package:app/features/simplified_mode/presentation/pages/simplified_snooze_screen.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_message.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_text_scale.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'routers.dart';

part 'routes/auth_routes.dart';
part 'routes/care_routes.dart';
part 'routes/circle_routes.dart';
part 'routes/home_routes.dart';
part 'routes/page_builders.dart';
part 'routes/simplified_routes.dart';

/// Defines page routes and navigation behavior.
class AppRouter {
  // How the app decides what to show:
  //
  // 1. The first page is the splash page. It asks the server whether this
  //    phone is signed in, then goes to the home page or the sign-in page.
  // 2. Every other page needs the tokens of a signed-in phone. Without them
  //    the router sends the user to the sign-in page, however the page was
  //    asked for: a tap, an address typed in the browser, or a reload. This
  //    only decides what the app shows. The data is protected by the server,
  //    which refuses every request that has no valid token.
  // 3. On the web a reload keeps the address, so the first navigation is
  //    also sent to the splash page, which checks the session with the
  //    server. A phone always starts at the splash page.
  static bool _startChecked = false;

  static final GoRouter router = GoRouter(
    initialLocation: Routes.splash,
    redirect: (context, state) async {
      final String location = state.matchedLocation;
      if (kIsWeb && !_startChecked) {
        _startChecked = true;
        if (location != Routes.splash) return Routes.splash;
      }
      String? token;
      try {
        token = await GetIt.I<TokenStorage>().readAccessToken();
      } catch (_) {
        // The tokens cannot be read (the secure storage failed): the phone
        // counts as signed out.
      }
      return signInRedirect(
        location,
        hasTokens: token != null && token.isNotEmpty,
      );
    },
    routes: <RouteBase>[
      GoRoute(
        path: Routes.splash,
        pageBuilder: _iosPage(
          (context, state) => BlocProvider(
            create: (context) => SplashCubit(GetIt.I<AuthUseCase>())..decide(),
            child: const SplashScreen(),
          ),
        ),
      ),
      GoRoute(path: Routes.home, redirect: (context, state) => Routes.today),
      _simplifiedShell(),
      _homeShell(),
      ..._careRoutes(),
      ..._accountRoutes(),
      _signInShell(),
      _onboardingShell(),
      ..._circleRoutes(),
      if (kDebugMode)
        GoRoute(
          path: Routes.gallery,
          pageBuilder: _iosPage((context, state) => const ComponentGallery()),
        ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text(context.tr('error.not_found')))),
  );

  /// The page a phone is sent to instead of [location], or null when it may
  /// open [location]. The splash page and the sign-in pages are open to
  /// everyone, and in a debug build the component gallery too (it exists
  /// only there). Every other page needs the tokens ([hasTokens]); without
  /// them the phone is sent to the sign-in page.
  @visibleForTesting
  static String? signInRedirect(String location, {required bool hasTokens}) {
    if (hasTokens) return null;
    final bool open =
        location == Routes.splash ||
        (kDebugMode && location == Routes.gallery) ||
        location == Routes.auth ||
        location.startsWith('${Routes.auth}/');
    return open ? null : Routes.auth;
  }
}
