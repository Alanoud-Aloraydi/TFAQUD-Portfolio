import 'dart:async';

import 'package:app/core/services/calendar_sync.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

/// The calendar-sync switches of one circle for a widget's [State]: reads
/// each kind's saved choice once and saves a change at once. The detailed
/// mode's calendar group and the simplified mode's share it, so both keep
/// the same [CalendarSync] choices the same way.
mixin CalendarSyncChoices<T extends StatefulWidget> on State<T> {
  final CalendarSync _calendar = GetIt.I<CalendarSync>();

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
    setState(() {
      enabled = <CalendarSyncCategory, bool>{...current, category: value};
    });
    await _calendar.setEnabled(calendarCircleId, category, value);
  }
}
