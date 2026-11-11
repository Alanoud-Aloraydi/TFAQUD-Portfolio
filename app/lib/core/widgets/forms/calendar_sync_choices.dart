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

/// The calendar-sync switches of one circle for a widget's [State]: reads
/// each kind's saved choice once and saves a change at once. The detailed
/// mode's calendar group and the simplified mode's share it, so both keep
/// the same [CalendarSync] choices the same way.
mixin CalendarSyncChoices<T extends StatefulWidget> on State<T> {
  final CalendarSync _calendar = GetIt.I<CalendarSync>();
  bool _confirmingEnable = false;

  /// The circle whose choices these are.
  String get calendarCircleId;

  /// Each kind's choice; null while the saved values load.
  Map<CalendarSyncCategory, bool>? enabled;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final String circleId = calendarCircleId;
    final Map<CalendarSyncCategory, bool> values = <CalendarSyncCategory, bool>{
      for (final CalendarSyncCategory category in CalendarSyncCategory.values)
        category: await _calendar.isEnabled(circleId, category),
    };
    if (mounted && circleId == calendarCircleId) {
      setState(() => enabled = values);
    }
  }

  /// Shows [value] for [category] now and saves it; nothing while the
  /// saved values are still loading.
  Future<void> setChoice(CalendarSyncCategory category, bool value) async {
    final Map<CalendarSyncCategory, bool>? current = enabled;
    if (current == null) return;
    if (current[category] == value) return;
    // Ask only when calendar copying changes from fully off to on. Once it is
    // active, enabling another category is an adjustment to the same choice.
    if (value && !current.values.any((bool selected) => selected)) {
      if (_confirmingEnable) return;
      _confirmingEnable = true;
      final bool confirmed = await confirmCalendarSync(context);
      _confirmingEnable = false;
      if (!mounted || !confirmed || enabled != current) return;
    }
    setState(() {
      enabled = <CalendarSyncCategory, bool>{...current, category: value};
    });
    await _calendar.setEnabled(calendarCircleId, category, value);
  }
}
