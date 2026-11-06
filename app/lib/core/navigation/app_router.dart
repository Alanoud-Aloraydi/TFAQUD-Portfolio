import 'dart:async';

import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/navigation/fading_branches.dart';
import 'package:app/core/services/intro_memory.dart';
import 'package:app/core/services/token_storage.dart';
import 'package:app/dev/component_gallery.dart';
import 'package:app/features/auth/domain/use_cases/auth_use_case.dart';
import 'package:app/features/appointments/data/appointment_repository.dart';
import 'package:app/features/appointments/data/visit_audio_service.dart';
import 'package:app/features/appointments/data/visit_repository.dart';
import 'package:app/features/appointments/presentation/cubit/appointment_companions_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:app/features/appointments/presentation/pages/appointment_form_page.dart';
import 'package:app/features/appointments/presentation/pages/visit_page.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/pages/account_screen.dart';
import 'package:app/features/account/presentation/pages/account_edit_screen.dart';
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
import 'package:app/features/medications/domain/dose_reminders.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/pages/medication_details_page.dart';
import 'package:app/features/medications/presentation/pages/medication_form_page.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_cubit.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_page.dart';
import 'package:app/features/onboarding/domain/use_cases/onboarding_use_case.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/pages/onboarding_feature_screen.dart';
import 'package:app/features/onboarding/presentation/pages/start_screen.dart';
import 'package:app/features/prayer_times/data/prayer_times_repository.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb, visibleForTesting;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'routers.dart';

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
      StatefulShellRoute(
        // The tabs fade into each other instead of swapping at once.
        navigatorContainerBuilder: (context, navigationShell, children) =>
            FadingBranches(
              currentIndex: navigationShell.currentIndex,
              children: children,
            ),
        // The home cubit loads the circles. The inbox cubit counts what waits
        // for an answer, for the dot on the bell; it loads again whenever the
        // circles change.
        pageBuilder: _iosShellRootPage(
          (context, state, navigationShell) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) =>
                    HomeCubit(
                        GetIt.I<HomeUseCase>(),
                        GetIt.I<PrivatePhotoRepository>().changes,
                      )
                      ..load(),
              ),
              BlocProvider(
                create: (context) => InboxCubit(
                  GetIt.I<CirclesUseCase>(),
                  GetIt.I<HomeUseCase>(),
                  followCircleChanges: true,
                )..load(),
              ),
              BlocProvider(
                create: (context) =>
                    MedicationsCubit(GetIt.I<MedicationsUseCase>()),
              ),
              BlocProvider(
                create: (context) =>
                    MedicationOccurrencesCubit(GetIt.I<MedicationsUseCase>(), GetIt.I<PrivatePhotoRepository>().changes),
              ),
              BlocProvider(
                create: (context) =>
                    MeasurementPlansCubit(GetIt.I<MeasurementRepository>()),
              ),
              BlocProvider(
                create: (context) =>
                    MeasurementTasksCubit(GetIt.I<MeasurementRepository>(), GetIt.I<PrivatePhotoRepository>().changes),
              ),
              BlocProvider(
                create: (context) =>
                    MeasurementReadingsCubit(GetIt.I<MeasurementRepository>(), GetIt.I<PrivatePhotoRepository>().changes),
              ),
              BlocProvider(
                create: (context) =>
                    AppointmentsCubit(GetIt.I<AppointmentRepository>()),
              ),
              BlocProvider(
                create: (context) =>
                    PrayerTimesCubit(GetIt.I<PrayerTimesRepository>()),
              ),
            ],
            child: HomeFeatureScreen(navigationShell: navigationShell),
          ),
        ),
        branches: <StatefulShellBranch>[
          _branch(Routes.today, builder: (context, state) => const TodayPage()),
          _branch(Routes.plan, builder: (context, state) => const PlanPage()),
          _branch(
            Routes.record,
            builder: (context, state) => const RecordPage(),
          ),
          // The circle tab shows the selected circle with the buttons of its
          // medical file and its emergency card.
          _branch(
            Routes.circle,
            builder: (context, state) => const CircleTabScreen(),
          ),
        ],
      ),
      GoRoute(
        path: Routes.medicationNewPath,
        pageBuilder: _iosPage((context, state) {
          final String circleId = state.pathParameters['circleId']!;
          return BlocProvider(
            create: (context) =>
                MedicationsCubit(GetIt.I<MedicationsUseCase>())..bind(circleId),
            child: MedicationFormPage(circleId: circleId),
          );
        }),
      ),
      GoRoute(
        path: Routes.measurementNewPath,
        pageBuilder: _iosPage((context, state) {
          final circleId = state.pathParameters['circleId']!;
          return BlocProvider(
            create: (_) =>
                MeasurementPlansCubit(GetIt.I<MeasurementRepository>())
                  ..load(circleId),
            child: MeasurementPlanFormPage(circleId: circleId),
          );
        }),
      ),
      GoRoute(
        path: Routes.measurementEditPath,
        pageBuilder: _iosPage((context, state) {
          final circleId = state.pathParameters['circleId']!;
          return BlocProvider(
            create: (_) =>
                MeasurementPlansCubit(GetIt.I<MeasurementRepository>())
                  ..load(circleId),
            child: MeasurementPlanFormPage(
              circleId: circleId,
              planId: state.pathParameters['planId']!,
            ),
          );
        }),
      ),
      GoRoute(
        path: Routes.appointmentNewPath,
        pageBuilder: _iosPage((context, state) {
          final circleId = state.pathParameters['circleId']!;
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) =>
                    AppointmentsCubit(GetIt.I<AppointmentRepository>())
                      ..load(circleId),
              ),
              BlocProvider(
                create: (_) =>
                    AppointmentCompanionsCubit(GetIt.I<AppointmentRepository>())
                      ..load(circleId),
              ),
            ],
            child: AppointmentFormPage(circleId: circleId),
          );
        }),
      ),
      GoRoute(
        path: Routes.appointmentEditPath,
        pageBuilder: _iosPage((context, state) {
          final circleId = state.pathParameters['circleId']!;
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) =>
                    AppointmentsCubit(GetIt.I<AppointmentRepository>())
                      ..load(circleId),
              ),
              BlocProvider(
                create: (_) =>
                    AppointmentCompanionsCubit(GetIt.I<AppointmentRepository>())
                      ..load(circleId),
              ),
            ],
            child: AppointmentFormPage(
              circleId: circleId,
              appointmentId: state.pathParameters['appointmentId'],
            ),
          );
        }),
      ),
      GoRoute(
        path: Routes.appointmentVisitPath,
        pageBuilder: _iosPage((context, state) {
          final circleId = state.pathParameters['circleId']!;
          final appointmentId = state.pathParameters['appointmentId']!;
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) =>
                    AppointmentsCubit(GetIt.I<AppointmentRepository>())
                      ..load(circleId),
              ),
              BlocProvider(
                create: (_) => VisitCubit(
                  GetIt.I<VisitRepository>(),
                  VisitAudioService(),
                  circleId,
                  appointmentId,
                )..load(),
              ),
            ],
            child: VisitPage(
              appointmentId: appointmentId,
              canManage: state.extra == true,
            ),
          );
        }),
      ),
      GoRoute(
        path: Routes.medicationDetailsPath,
        pageBuilder: _iosPage((context, state) {
          final String circleId = state.pathParameters['circleId']!;
          final String planId = state.pathParameters['planId']!;
          Widget details(bool canManage) => BlocProvider(
            create: (context) =>
                MedicationsCubit(GetIt.I<MedicationsUseCase>())
                  ..loadPlan(circleId, planId),
            child: MedicationDetailsPage(
              circleId: circleId,
              planId: planId,
              canManage: canManage,
            ),
          );
          if (state.extra case final bool canManage) {
            return details(canManage);
          }
          // A direct link has no tab context, so it resolves permission here.
          return BlocProvider(
            create: (context) =>
                HomeCubit(
                    GetIt.I<HomeUseCase>(),
                    GetIt.I<PrivatePhotoRepository>().changes,
                  )
                  ..load(),
            child: Builder(
              builder: (context) {
                final canManage = context.select<HomeCubit, bool>(
                  (cubit) =>
                      cubit.state.data?.circles.any(
                        (circle) =>
                            circle.id == circleId &&
                            circle.canManageMedications,
                      ) ??
                      false,
                );
                return details(canManage);
              },
            ),
          );
        }),
      ),
      GoRoute(
        path: Routes.medicationEditPath,
        pageBuilder: _iosModalPage((context, state) {
          final String circleId = state.pathParameters['circleId']!;
          final String planId = state.pathParameters['planId']!;
          return BlocProvider(
            create: (context) =>
                MedicationsCubit(GetIt.I<MedicationsUseCase>())
                  ..loadPlan(circleId, planId),
            child: MedicationFormPage(circleId: circleId, planId: planId),
          );
        }),
      ),
      // The account page: names, phone number, requests that wait for the
      // patient, sign-out (AuthCubit) and deleting the account.
      GoRoute(
        path: Routes.account,
        pageBuilder: _iosModalPage(
          (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => AccountCubit(
                  GetIt.I<CirclesUseCase>(),
                  GetIt.I<OnboardingUseCase>(),
                  GetIt.I<AuthUseCase>(),
                  GetIt.I<HomeUseCase>(),
                )..load(),
              ),
              BlocProvider(
                create: (context) => AuthCubit(GetIt.I<AuthUseCase>()),
              ),
            ],
            child: const AccountScreen(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.accountEdit,
        pageBuilder: _iosPage(
          (context, state) => BlocProvider(
            create: (context) => AccountCubit(
              GetIt.I<CirclesUseCase>(),
              GetIt.I<OnboardingUseCase>(),
              GetIt.I<AuthUseCase>(),
              GetIt.I<HomeUseCase>(),
            )..load(),
            child: const AccountEditScreen(),
          ),
        ),
      ),
      // Welcome, phone number and code share one SignInCubit, so the code page
      // knows the number. The cubit is closed when the user leaves these pages.
      ShellRoute(
        pageBuilder: _iosShellPage(
          (context, state, child) => BlocProvider(
            create: (context) => SignInCubit(GetIt.I<AuthUseCase>()),
            child: child,
          ),
        ),
        routes: <RouteBase>[
          GoRoute(
            path: Routes.auth,
            redirect: _welcomeOnce,
            pageBuilder: _iosPage(
              (context, state) => const AuthFeatureScreen(),
            ),
          ),
          GoRoute(
            path: Routes.authPhone,
            pageBuilder: _iosPage((context, state) => const PhoneScreen()),
          ),
          GoRoute(
            path: Routes.authCode,
            pageBuilder: _iosPage((context, state) => const CodeScreen()),
          ),
        ],
      ),
      // Name page and start page share one OnboardingCubit. The page that adds
      // another circle is the start page again, so it shares the cubit too.
      ShellRoute(
        pageBuilder: _iosShellPage(
          (context, state, child) => BlocProvider(
            create: (context) => OnboardingCubit(GetIt.I<OnboardingUseCase>()),
            child: child,
          ),
        ),
        routes: <RouteBase>[
          GoRoute(
            path: Routes.onboarding,
            pageBuilder: _iosPage(
              (context, state) => const OnboardingFeatureScreen(),
            ),
          ),
          GoRoute(
            path: Routes.onboardingStart,
            pageBuilder: _iosPage((context, state) => const StartScreen()),
          ),
          GoRoute(
            path: Routes.addCircle,
            pageBuilder: _iosPage(
              (context, state) => const StartScreen(addingCircle: true),
            ),
          ),
        ],
      ),
      // A circle is created on one page with its own CreateCircleCubit. The
      // circle for your own care loads the account at the start, to learn
      // whether it already has a circle and holds the birth date and city.
      // When the server says the sign-in ended, the page sends the user to
      // sign-in.
      _createCircleShell(
        flow: CircleFlow.self,
        routes: <RouteBase>[
          GoRoute(
            path: Routes.createSelfCircle,
            pageBuilder: _iosPage(
              (context, state) => const SelfCircleBasicsScreen(),
            ),
          ),
        ],
      ),
      // The same for a patient who does not use the app. The names
      // of the patient are typed, so no account is loaded.
      _createCircleShell(
        flow: CircleFlow.patient,
        routes: <RouteBase>[
          GoRoute(
            path: Routes.createPatientCircle,
            pageBuilder: _iosPage(
              (context, state) => const PatientCircleBasicsScreen(),
            ),
          ),
        ],
      ),
      // A request to a patient who uses the app: the phone number, then the
      // waiting state on the same page.
      GoRoute(
        path: Routes.requestPatient,
        pageBuilder: _iosPage(
          (context, state) => BlocProvider(
            create: (context) =>
                SendCircleRequestCubit(GetIt.I<CirclesUseCase>()),
            child: const RequestPatientScreen(),
          ),
        ),
      ),
      // What waits for an answer: invitations and requests. The page of a
      // request takes the patient's answer; "agree" leads to the basic data.
      GoRoute(
        path: Routes.notifications,
        pageBuilder: _iosModalPage(
          (context, state) => BlocProvider(
            create: (context) =>
                InboxCubit(GetIt.I<CirclesUseCase>(), GetIt.I<HomeUseCase>())
                  ..load(),
            child: const NotificationsScreen(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.replyRequest,
        redirect: _requireRequest,
        pageBuilder: _iosPage(
          (context, state) => BlocProvider(
            create: (context) => RequestReplyCubit(
              GetIt.I<CirclesUseCase>(),
              state.extra! as ReceivedCircleRequest,
            ),
            child: const RequestReplyScreen(),
          ),
        ),
      ),
      // The page after the patient agreed: it creates the circle. The request
      // travels with the page.
      _createCircleShell(
        flow: CircleFlow.approved,
        routes: <RouteBase>[
          GoRoute(
            path: Routes.completeRequest,
            redirect: _requireRequest,
            pageBuilder: _iosPage(
              (context, state) => const ApprovedCircleBasicsScreen(),
            ),
          ),
        ],
      ),
      // The medical file of a circle, its edit page and its emergency card.
      // Each page loads what it shows from the server for the circle in the
      // address.
      GoRoute(
        path: Routes.medicalFilePath,
        pageBuilder: _iosPage((context, state) {
          final String circleId = state.pathParameters['circleId']!;
          return BlocProvider(
            create: (context) =>
                MedicalFileCubit(GetIt.I<CirclesUseCase>(), circleId)..load(),
            child: MedicalFileScreen(circleId: circleId),
          );
        }),
      ),
      // The edit page starts from the file the medical file page passes
      // (no second read); opened from its address alone, it reads the file.
      GoRoute(
        path: Routes.medicalFileEditPath,
        pageBuilder: _iosPage(
          (context, state) => BlocProvider(
            create: (context) {
              final MedicalFileEditCubit cubit = MedicalFileEditCubit(
                GetIt.I<CirclesUseCase>(),
                state.pathParameters['circleId']!,
              );
              final Object? file = state.extra;
              if (file is MedicalFile) {
                cubit.start(file);
              } else {
                cubit.load();
              }
              return cubit;
            },
            child: const MedicalFileEditScreen(),
          ),
        ),
      ),
      GoRoute(
        path: Routes.emergencyCardPath,
        pageBuilder: _iosPage(
          (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => EmergencyCardCubit(
                  GetIt.I<CirclesUseCase>(),
                  state.pathParameters['circleId']!,
                )..load(),
              ),
              BlocProvider(
                create: (context) =>
                    MedicationsCubit(GetIt.I<MedicationsUseCase>())
                      ..load(state.pathParameters['circleId']!),
              ),
            ],
            child: const EmergencyCardScreen(),
          ),
        ),
      ),
      if (kDebugMode)
        GoRoute(
          path: Routes.gallery,
          pageBuilder: _iosPage((context, state) => const ComponentGallery()),
        ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text(context.tr('error.not_found')))),
  );

  /// The welcome shows once per install ([IntroMemory]). After it, a
  /// signed-out phone opens on the phone number page, and the reminders of
  /// the last person go, as the welcome would have removed them.
  static Future<String?> _welcomeOnce(
    BuildContext context,
    GoRouterState state,
  ) async {
    if (!await IntroMemory.seen()) return null;
    unawaited(GetIt.I<DoseReminders>().clear());
    return Routes.authPhone;
  }

  /// The page a phone is sent to instead of [location], or null when it may
  /// open [location]. The splash page, the sign-in pages and the debug
  /// gallery are open to everyone. Every other page needs the tokens
  /// ([hasTokens]); without them the phone is sent to the sign-in page.
  @visibleForTesting
  static String? signInRedirect(String location, {required bool hasTokens}) {
    if (hasTokens) return null;
    final bool open =
        location == Routes.splash ||
        location == Routes.gallery ||
        location == Routes.auth ||
        location.startsWith('${Routes.auth}/');
    return open ? null : Routes.auth;
  }

  static ShellRoute _createCircleShell({
    required CircleFlow flow,
    required List<RouteBase> routes,
  }) {
    return ShellRoute(
      pageBuilder: _iosShellPage(
        (context, state, child) => BlocProvider(
          create: (context) {
            final Object? extra = state.extra;
            final CreateCircleCubit cubit = CreateCircleCubit(
              GetIt.I<CirclesUseCase>(),
              GetIt.I<HomeUseCase>(),
              flow: flow,
              request: extra is ReceivedCircleRequest ? extra : null,
            );
            // The name field reads the account, and the account says at once
            // whether it already has a circle of its own care. The names of a
            // patient without the app are typed, so nothing is loaded for them.
            if (flow != CircleFlow.patient) cubit.loadAccount();
            return cubit;
          },
          child: BlocListener<CreateCircleCubit, CreateCircleState>(
            listenWhen: (before, after) =>
                after.sessionEnded && !before.sessionEnded,
            listener: (context, state) => context.go(Routes.auth),
            child: child,
          ),
        ),
      ),
      routes: routes,
    );
  }

  static StatefulShellBranch _branch(
    String path, {
    GoRouterWidgetBuilder? builder,
  }) {
    final GoRouterWidgetBuilder page =
        builder ?? (context, state) => const SizedBox.expand();
    return StatefulShellBranch(
      routes: <RouteBase>[
        GoRoute(
          path: path,
          // A tab page is the first page of its own navigator and has no
          // background of its own: the shell's canvas shows through it. An
          // iOS page (CupertinoPage) draws a light shadow (9% black) under
          // itself, which over a see-through page darkened the whole tab and
          // left a lighter band under the top bar. A tab page never slides
          // in (tabs fade, FadingBranches), so it is a plain page.
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: state.pageKey,
            name: state.name ?? state.path,
            restorationId: state.pageKey.value,
            child: page(context, state),
          ),
        ),
      ],
    );
  }

  /// A page of the patient's side of a request needs the request, which
  /// travels as the `extra` of the navigation. Without it (an address typed in
  /// the browser, a restored page) the notifications page is the way in.
  static String? _requireRequest(BuildContext context, GoRouterState state) {
    return state.extra is ReceivedCircleRequest ? null : Routes.notifications;
  }
}

// Detail pages change without a horizontal push animation.
GoRouterPageBuilder _iosPage(GoRouterWidgetBuilder builder) =>
    (BuildContext context, GoRouterState state) => NoTransitionPage<void>(
      key: state.pageKey,
      name: state.name ?? state.path,
      restorationId: state.pageKey.value,
      child: builder(context, state),
    );

// The notifications (the bell) and the account open as an iOS full-screen
// modal: the page rises from the bottom and goes back down when closed, and
// the page under it stays still. A modal has no back arrow and no edge
// swipe; its top has the close button (✕) instead, on the leading side, as
// Apple's guidelines ask for a modal view (Human Interface Guidelines,
// Modality and Sheets).
GoRouterPageBuilder _iosModalPage(GoRouterWidgetBuilder builder) =>
    (BuildContext context, GoRouterState state) => CupertinoPage<void>(
      key: state.pageKey,
      name: state.name ?? state.path,
      restorationId: state.pageKey.value,
      fullscreenDialog: true,
      child: builder(context, state),
    );

ShellRoutePageBuilder _iosShellPage(ShellRouteBuilder builder) =>
    (BuildContext context, GoRouterState state, Widget child) =>
        CupertinoPage<void>(
          key: state.pageKey,
          restorationId: state.pageKey.value,
          child: builder(context, state, child),
        );

StatefulShellRoutePageBuilder _iosShellRootPage(
  StatefulShellRouteBuilder builder,
) =>
    (
      BuildContext context,
      GoRouterState state,
      StatefulNavigationShell navigationShell,
    ) => CupertinoPage<void>(
      key: state.pageKey,
      restorationId: state.pageKey.value,
      child: builder(context, state, navigationShell),
    );
