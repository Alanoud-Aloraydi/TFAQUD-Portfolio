import 'package:app/core/services/calendar_sync.dart';
import 'package:app/features/account/presentation/widgets/settings_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// The per-circle, per-category calendar-sync toggles: doses,
/// measurements, and appointments. Shared by the circle tab (detailed
/// mode) and the simplified-mode account screen.
class CalendarSyncSection extends StatelessWidget {
  const CalendarSyncSection({super.key, required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: context.tr('circle_overview.calendar_sync_title'),
      children: <Widget>[
        _CalendarSyncRow(
          circleId: circleId,
          category: CalendarSyncCategory.doses,
          label: context.tr('circle_overview.calendar_sync_doses'),
        ),
        _CalendarSyncRow(
          circleId: circleId,
          category: CalendarSyncCategory.measurements,
          label: context.tr('circle_overview.calendar_sync_measurements'),
        ),
        _CalendarSyncRow(
          circleId: circleId,
          category: CalendarSyncCategory.appointments,
          label: context.tr('circle_overview.calendar_sync_appointments'),
          hint: context.tr('circle_overview.calendar_sync_hint'),
        ),
      ],
    );
  }
}

/// A calendar-sync toggle for one circle and category, off by default, its
/// own value loaded once.
class _CalendarSyncRow extends StatefulWidget {
  const _CalendarSyncRow({
    required this.circleId,
    required this.category,
    required this.label,
    this.hint,
  });

  final String circleId;
  final CalendarSyncCategory category;
  final String label;
  final String? hint;

  @override
  State<_CalendarSyncRow> createState() => _CalendarSyncRowState();
}

class _CalendarSyncRowState extends State<_CalendarSyncRow> {
  final CalendarSync _calendar = GetIt.I<CalendarSync>();
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await _calendar.isEnabled(widget.circleId, widget.category);
    if (mounted) setState(() => _enabled = value);
  }

  Future<void> _onChanged(bool value) async {
    setState(() => _enabled = value);
    await _calendar.setEnabled(widget.circleId, widget.category, value);
  }

  @override
  Widget build(BuildContext context) {
    return ToggleRow(
      label: widget.label,
      hint: widget.hint,
      value: _enabled ?? false,
      onChanged: _enabled == null ? (_) {} : _onChanged,
    );
  }
}
