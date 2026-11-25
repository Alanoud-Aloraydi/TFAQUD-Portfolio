import 'dart:async';

import 'package:app/app/services/calendar_sync.dart';
import 'package:app/app/services/permissions/app_permission.dart';
import 'package:app/core/widgets/forms/permission_confirm.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// The one line under the calendar switches that says the phone refuses,
/// with the way to its Settings.
///
/// The refusal is a fact about the phone, not about one circle, so it is
/// said once for the whole list: under each blocked circle it repeated
/// «افتح الإعدادات» as many times as there were circles. Nothing is said
/// until someone has actually asked for a copy.
class CalendarSyncNotice extends StatefulWidget {
  const CalendarSyncNotice({super.key, required this.circleIds});

  final List<String> circleIds;

  @override
  State<CalendarSyncNotice> createState() => _CalendarSyncNoticeState();
}

class _CalendarSyncNoticeState extends State<CalendarSyncNotice> {
  final CalendarSync _calendar = GetIt.I<CalendarSync>();
  AppLifecycleListener? _lifecycle;
  AppPermission? _access;
  bool _anyChosen = false;

  @override
  void initState() {
    super.initState();
    // Read again on the way back from Settings, where the answer changes.
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(_load()));
    unawaited(_load());
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final AppPermission permission = await _calendar.permission();
    bool chosen = false;
    for (final String id in widget.circleIds) {
      if (await _calendar.isCircleEnabled(id)) chosen = true;
    }
    if (!mounted) return;
    setState(() {
      _access = permission;
      _anyChosen = chosen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppPermission? access = _access;
    if (access == null || !_anyChosen) return const SizedBox.shrink();
    if (!access.usable) {
      return const PermissionDeniedRow(
        messageKey: 'circle_overview.calendar_access_denied',
      );
    }
    if (access == AppPermission.partial) {
      return const PermissionDeniedRow(
        messageKey: 'circle_overview.calendar_access_partial',
      );
    }
    return const SizedBox.shrink();
  }
}
