import 'package:app/app/dev/gallery_buttons_section.dart';
import 'package:app/app/dev/gallery_chips_section.dart';
import 'package:app/app/router/page_builders.dart';
import 'package:app/app/router/routers.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/features/account/presentation/pages/account_edit_screen.dart';
import 'package:app/features/appointments/routing/appointment_routes.dart';
import 'package:app/features/auth/domain/usecases/auth_use_case.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/auth/presentation/cubit/splash_cubit.dart';
import 'package:app/features/auth/presentation/pages/splash_screen.dart';
import 'package:app/features/circles/routing/circle_routes.dart';
import 'package:app/features/home/routing/home_routes.dart';
import 'package:app/features/home/routing/loaded_account_cubit.dart';
import 'package:app/features/medications/routing/medication_routes.dart';
import 'package:app/features/onboarding/routing/onboarding_routes.dart';
import 'package:app/features/simplified_mode/routing/simplified_routes.dart';
import 'package:dio/dio.dart' show Response;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// Every page of the app, in the order the router matches them.
List<RouteBase> appRoutes() => <RouteBase>[
  GoRoute(
    path: Routes.splash,
    pageBuilder: iosPage(
      (context, state) => BlocProvider(
        create: (context) => SplashCubit(GetIt.I<AuthUseCase>())..decide(),
        child: const SplashScreen(),
      ),
    ),
  ),
  GoRoute(path: Routes.home, redirect: (context, state) => Routes.today),
  simplifiedShell(),
  homeShell(),
  ...careRoutes(),
  ...accountRoutes(),
  signInShell(),
  onboardingShell(),
  ...circleRoutes(),
  if (kDebugMode)
    GoRoute(
      path: Routes.gallery,
      pageBuilder: iosPage((context, state) => const ComponentGallery()),
    ),
];

/// The pages of a circle's medicines, measurements and appointments, opened
/// from the home tabs. Each one loads what it shows for the circle in the
/// address.
List<RouteBase> careRoutes() => <RouteBase>[
  medicationNewRoute(),
  ...measurementRoutes(),
  ...appointmentRoutes(),
  ...medicationPlanRoutes(),
];

/// The account page and its edit page.
List<RouteBase> accountRoutes() => <RouteBase>[
  // The account page: names, phone number, requests that wait for the
  // patient, sign-out (AuthCubit) and deleting the account.
  GoRoute(
    path: Routes.account,
    pageBuilder: iosModalPage(
      (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => loadedAccountCubit()),
          BlocProvider(create: (context) => AuthCubit(GetIt.I<AuthUseCase>())),
        ],
        child: const AccountScreen(),
      ),
    ),
  ),
  GoRoute(
    path: Routes.accountEdit,
    pageBuilder: iosPage(
      (context, state) => BlocProvider(
        create: (context) => loadedAccountCubit(),
        child: const AccountEditScreen(),
      ),
    ),
  ),
];

/// Development-only page that shows the shared components and checks the
/// connection to the API. It is registered in the router only when kDebugMode
/// is true.
class ComponentGallery extends StatefulWidget {
  const ComponentGallery({super.key});

  @override
  State<ComponentGallery> createState() => _ComponentGalleryState();
}

class _ComponentGalleryState extends State<ComponentGallery> {
  int _chip = 0;
  String _apiStatus = '';
  bool _apiBusy = false;

  Future<void> _checkApi() async {
    setState(() {
      _apiBusy = true;
      _apiStatus = '';
    });
    final String status = await checkGalleryApi();
    if (!mounted) return;
    setState(() {
      _apiBusy = false;
      _apiStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const GalleryButtonsSection(),
          const GalleryFieldsSection(),
          GalleryChipsSection(
            selected: _chip,
            onSelected: (int i) => setState(() => _chip = i),
          ),
          const GalleryCardSection(),
          const GalleryOverlaysSection(),
          const GalleryIconsSection(),
          GalleryApiSection(
            busy: _apiBusy,
            status: _apiStatus,
            onCheck: _checkApi,
          ),
        ],
      ),
    );
  }
}

/// Calls GET /health and returns the address used and the result.
Future<String> checkGalleryApi() async {
  try {
    final Response<dynamic> response = await GetIt.I<DioClient>().get(
      ApiEndpoints.health,
    );
    return 'GET ${ApiEndpoints.baseUrl}${ApiEndpoints.health}\n'
        'HTTP ${response.statusCode}';
  } catch (error) {
    final Failure failure = FailureExceptions.getException(error);
    return '${failure.messageKey.tr()} (${error.runtimeType})';
  }
}

/// The dialog and the bottom sheet of the gallery.
class GalleryOverlaysSection extends StatelessWidget {
  const GalleryOverlaysSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Dialog and bottom sheet',
      children: <Widget>[
        FilledButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (BuildContext ctx) => AlertDialog(
              title: const Text('Title'),
              content: const Text('Dialog body text.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ),
          child: const Text('Open dialog'),
        ),
        OutlinedButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext ctx) => const SizedBox(
              height: 200,
              child: Center(child: Text('Bottom sheet')),
            ),
          ),
          child: const Text('Open bottom sheet'),
        ),
      ],
    );
  }
}

/// The icons of the gallery.
class GalleryIconsSection extends StatelessWidget {
  const GalleryIconsSection({super.key});

  static const List<IconData> _icons = <IconData>[
    ArrowIcons.back,
    ActionIcons.check,
    ActionIcons.plus,
    NoticeIcons.bell,
    PeopleIcons.user,
    PeopleIcons.users,
    NoticeIcons.info,
    NoticeIcons.warning,
    ScheduleIcons.clock,
    ScheduleIcons.calendar,
    CareIcons.pill,
    CareIcons.heart,
    CareIcons.drop,
    ActionIcons.search,
    ActionIcons.trash,
    ActionIcons.pencil,
    NoticeIcons.export,
  ];

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Icons (Material)',
      children: <Widget>[
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: <Widget>[
            for (final IconData icon in _icons) Icon(icon, size: AppSizes.icon),
          ],
        ),
      ],
    );
  }
}
