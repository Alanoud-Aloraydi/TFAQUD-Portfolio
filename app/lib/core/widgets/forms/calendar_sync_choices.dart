import 'dart:async';

import 'package:app/core/services/calendar_sync.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// Explains the one-way calendar copy before it is enabled for a circle.
/// Both app modes use this dialog through [CalendarSyncChoices].
Future<bool> confirmCalendarSync(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            dialogContext.tr('circle_overview.calendar_sync_confirm_title'),
          ),
          content: Text(
            dialogContext.tr('circle_overview.calendar_sync_confirm_text'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                dialogContext.tr(
                  'circle_overview.calendar_sync_confirm_cancel',
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                dialogContext.tr(
                  'circle_overview.calendar_sync_confirm_accept',
                ),
              ),
            ),
          ],
        ),
      ) ??
      false;
}

/// One circle's calendar switch for a widget's [State]: reads the saved
/// choice once and saves a change at once. Both app modes share it, so they
/// keep the same [CalendarSync] choices the same way.
mixin CalendarSyncChoices<T extends StatefulWidget> on State<T> {
  final CalendarSync _calendar = GetIt.I<CalendarSync>();
  bool _confirming = false;

  /// The circle whose choice this is.
  String get calendarCircleId;

  /// Whether the circle is copied to the calendar; null while it loads.
  bool? enabled;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final String circleId = calendarCircleId;
    final bool value = await _calendar.isCircleEnabled(circleId);
    if (mounted && circleId == calendarCircleId) {
      setState(() => enabled = value);
    }
  }

  /// Shows [value] now and saves it, for every kind at once. Turning the
  /// copy on explains it first; nothing happens while the saved value is
  /// still loading.
  Future<void> setChoice(bool value) async {
    final bool? current = enabled;
    if (current == null || current == value) return;
    if (value) {
      if (_confirming) return;
      _confirming = true;
      final bool confirmed = await confirmCalendarSync(context);
      _confirming = false;
      if (!mounted || !confirmed || enabled != current) return;
    }
    setState(() => enabled = value);
    await _calendar.setCircleEnabled(calendarCircleId, value);
  }
}
