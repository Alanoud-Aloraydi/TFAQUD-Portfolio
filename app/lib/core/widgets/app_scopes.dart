import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/navigation/app_router.dart';
import 'package:app/core/services/app_accessibility.dart';
import 'package:app/core/services/remote_push.dart';
import 'package:app/core/services/shown_circle_clock.dart';
import 'package:app/core/theme/components/navigation_themes.dart';
import 'package:app/core/theme/materials/glass_preferences.dart';
import 'package:app/core/widgets/calendar_scope.dart';
import 'package:app/core/widgets/feedback/push_setup_check.dart';
import 'package:app/core/widgets/forms/keyboard_dismiss.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// What every page sits in, between the router and the page: the status
/// bar's icons, the private photos, the glass preference, the shown
/// patient's clock, the chosen calendar, OneSignal's debug check and the
/// tap that closes the keyboard.
class AppScopes extends StatelessWidget {
  const AppScopes({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Dark status bar icons on every page, also the ones without an app bar
    // (the tabs draw their own glass top bar).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppNavigationThemes.systemBars,
      child: RepositoryProvider<PrivatePhotoRepository>.value(
        value: GetIt.I<PrivatePhotoRepository>(),
        child: ValueListenableBuilder<bool>(
          valueListenable: AppAccessibility.reduceTransparency,
          builder: (context, reduceTransparency, _) => GlassPreferences(
            reduceTransparency: reduceTransparency,
            // Above the router's pages, so a page opened on the root
            // navigator reads the same patient's clock.
            child: ValueListenableBuilder(
              valueListenable: GetIt.I<ShownCircleClock>(),
              builder: (context, clock, _) => PatientClockScope(
                clock: clock,
                // OneSignal's setup check, in a debug build only.
                child: CalendarScope(
                  child: PushSetupCheck(
                    push: GetIt.I<RemotePush>(),
                    navigatorKey: AppRouter.router.routerDelegate.navigatorKey,
                    child: KeyboardDismissOnTap(child: child),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
