import 'dart:async';

import 'package:app/app/router/app_router.dart';
import 'package:app/app/services/app_accessibility.dart';
import 'package:app/app/services/remote_push.dart';
import 'package:app/app/services/shown_circle_clock.dart';
import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/theme/components/navigation_themes.dart';
import 'package:app/core/theme/materials/glass_style.dart';
import 'package:app/core/widgets/calendar_scope.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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

/// Closes the keyboard when the user touches anywhere outside the text
/// fields, as iOS apps do. A number pad has no return key, so without this
/// the keyboard would stay open.
///
/// Flutter asks [EditableTextTapOutsideIntent] what to do on such a touch;
/// on a phone its default does nothing. This widget wraps the whole app and
/// answers it: the field loses focus and the keyboard goes down. A touch on
/// another text field counts as inside, so moving between fields keeps the
/// keyboard up. Dragging a form also closes it (each form's scroll view
/// uses `ScrollViewKeyboardDismissBehavior.onDrag`).
class KeyboardDismissOnTap extends StatelessWidget {
  const KeyboardDismissOnTap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        EditableTextTapOutsideIntent:
            CallbackAction<EditableTextTapOutsideIntent>(
              onInvoke: (EditableTextTapOutsideIntent intent) {
                intent.focusNode.unfocus();
                return null;
              },
            ),
      },
      child: child,
    );
  }
}

/// OneSignal's setup check, in a debug build only: once OneSignal's servers
/// have registered this phone (a real subscription id, not `local-…`), one
/// dialog says the setup works, and its button asks for the notification
/// permission. The app people use never shows it; there the app asks for
/// the permission as before.
///
/// Its words are OneSignal's own check, in English, for the developer.
class PushSetupCheck extends StatefulWidget {
  const PushSetupCheck({
    super.key,
    required this.push,
    required this.navigatorKey,
    required this.child,
    this.enabled = kDebugMode,
  });

  final RemotePush push;

  /// The app's root navigator, which the dialog opens on.
  final GlobalKey<NavigatorState> navigatorKey;

  final Widget child;

  /// Whether the check runs; only in a debug build unless a test says so.
  final bool enabled;

  @override
  State<PushSetupCheck> createState() => _PushSetupCheckState();
}

class _PushSetupCheckState extends State<PushSetupCheck> {
  /// Kept here for as long as the app runs: OneSignal holds its observers
  /// weakly, and a local one would be gone before it is called.
  late final RemotePushObserver _observer = _check;

  /// The dialog shows once per run.
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) return;
    widget.push.addSubscriptionObserver(_observer);
    // The id may be there before the observer: look at it now too.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _check(widget.push.subscriptionId),
    );
  }

  @override
  void dispose() {
    widget.push.removeSubscriptionObserver(_observer);
    super.dispose();
  }

  void _check(String? subscriptionId) {
    if (_shown || !mounted || !isRegisteredSubscription(subscriptionId)) {
      return;
    }
    final BuildContext? context = widget.navigatorKey.currentContext;
    if (context == null) {
      // The first page is not up yet: try again after the next frame.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _check(subscriptionId),
      );
      return;
    }
    _shown = true;
    final Future<void> shown = showCupertinoDialog<void>(
      context: context,
      builder: (_) => PushSetupDialog(push: widget.push),
    );
    unawaited(shown);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// OneSignal's own check dialog, in English for the developer: the setup
/// works, and its button asks for the notification permission.
class PushSetupDialog extends StatelessWidget {
  const PushSetupDialog({super.key, required this.push});

  final RemotePush push;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Your OneSignal SDK integration is complete!'),
      content: const Text(
        'You can now send Push Notifications & In-App Messages through '
        'OneSignal. Tap below to enable push notifications.',
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.of(context).pop();
            unawaited(push.requestPermission());
          },
          child: const Text('Got it'),
        ),
      ],
    );
  }
}
