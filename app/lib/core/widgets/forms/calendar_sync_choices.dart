import 'dart:async';

import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/services/permissions/app_permission.dart';
import 'package:app/core/widgets/forms/calendar_sync_confirm.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

/// One circle's calendar switch for a widget's [State]. The switch follows
/// the phone, not a saved wish: it is on only while the choice is saved
/// *and* the phone still allows the calendar, and it is read again on every
/// resume, because the person can refuse the calendar in Settings while the
/// app is away. Both app modes share it, so both behave the same way.
mixin CalendarSyncChoices<T extends StatefulWidget> on State<T> {
  final CalendarSync _calendar = GetIt.I<CalendarSync>();
  AppLifecycleListener? _lifecycle;
  bool _confirming = false;
  bool? _chosen;

  /// The circle whose choice this is.
  String get calendarCircleId;

  /// What the phone allows; null while it loads.
  AppPermission? access;

  /// Whether the circle is copied to the calendar; null while it loads.
  bool? get enabled => _chosen == null || access == null
      ? null
      : _chosen! && access!.usable;

  /// Whether the person asked for the copy but the phone refuses it, so the
  /// screen should offer the phone's Settings.
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

  /// Saves [value] for every kind at once. Turning the copy on explains it
  /// first, then asks the phone: a refused calendar saves nothing, so the
  /// switch stays off instead of promising a copy that cannot happen.
  Future<void> setChoice(bool value) async {
    final bool? current = _chosen;
    if (current == null || current == value) return;
    if (value && !await _agreedAndAllowed(current)) return;
    setState(() => _chosen = value);
    await _calendar.setCircleEnabled(calendarCircleId, value);
  }

  /// The explanation, then the phone's own question; false when either is
  /// refused, or when the choice changed while they were open.
  Future<bool> _agreedAndAllowed(bool current) async {
    if (_confirming) return false;
    _confirming = true;
    final bool confirmed = await confirmCalendarSync(context);
    final AppPermission permission = confirmed
        ? await _calendar.requestPermission()
        : AppPermission.denied;
    _confirming = false;
    if (!mounted) return false;
    setState(() => access = permission);
    return confirmed && permission.usable && _chosen == current;
  }
}
