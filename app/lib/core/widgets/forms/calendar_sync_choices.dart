import 'dart:async';

import 'package:app/app/services/calendar_sync.dart';
import 'package:app/app/services/permissions/app_permission.dart';
import 'package:app/core/widgets/forms/leave_for_settings.dart';
import 'package:app/core/widgets/forms/permission_confirm.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

/// One circle's calendar switch for a widget's [State], in both app modes,
/// read again on every resume. It shows the saved choice even when the phone
/// refuses the calendar later: what was copied stays on the calendar.
mixin CalendarSyncChoices<T extends StatefulWidget> on State<T> {
  final CalendarSync _calendar = GetIt.I<CalendarSync>();
  AppLifecycleListener? _lifecycle;
  bool _confirming = false;
  bool? _chosen;

  /// The circle whose choice this is.
  String get calendarCircleId;

  /// What the phone allows; null while it loads.
  AppPermission? access;

  /// Whether the circle is chosen for the calendar; null while it loads.
  bool? get enabled => access == null ? null : _chosen;

  /// Asked for, but the phone refuses; the screen says so.
  bool get blocked => _chosen == true && access?.usable == false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(_load()));
    unawaited(_load());
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final String circleId = calendarCircleId;
    final bool chosen = await _calendar.isCircleEnabled(circleId);
    final AppPermission permission = await _calendar.permission();
    if (!mounted || circleId != calendarCircleId) return;
    setState(() {
      _chosen = chosen;
      access = permission;
    });
  }

  /// Saves [value] for every kind; turning on explains, then asks the phone.
  /// A calendar locked in Settings is not asked again (iOS asks once), and
  /// its switch does not move: a word, then the Settings.
  Future<void> setChoice(bool value) async {
    final bool? current = _chosen;
    if (current == null || _confirming) return;
    if (access == AppPermission.denied) {
      // Locked: the switch keeps what it was, on or off.
      return leaveForSettings(
        context,
        'circle_overview.calendar_opening',
        failedKey: 'circle_overview.open_settings_failed',
      );
    }
    if (current == value) return;
    if (value && !await _agreedAndAllowed(current)) return;
    setState(() => _chosen = value);
    await _calendar.setCircleEnabled(calendarCircleId, value);
  }

  /// The explanation, then the phone's question; false if either says no.
  Future<bool> _agreedAndAllowed(bool current) async {
    _confirming = true;
    final bool confirmed = await confirmPermission(
      context,
      'circle_overview.calendar_sync_confirm',
    );
    final AppPermission? permission = confirmed
        ? await _calendar.requestPermission()
        : access;
    _confirming = false;
    if (!mounted) return false;
    setState(() => access = permission);
    return confirmed && (permission?.usable ?? false) && _chosen == current;
  }
}
