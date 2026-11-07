import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/account/presentation/widgets/settings_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// The calendar-sync toggles (doses, measurements, appointments) for one
/// circle: no title of its own, so a page with several circles can put its
/// own title and a shared hint around as many of these as it needs.
class CalendarSyncToggles extends StatelessWidget {
  const CalendarSyncToggles({super.key, required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
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
        ),
      ],
    );
  }
}

/// The one explanation of what calendar sync does, shown once beneath
/// however many circles' toggles a page lists.
class CalendarSyncHint extends StatelessWidget {
  const CalendarSyncHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpacing.sm,
        start: AppSpacing.inset,
        end: AppSpacing.inset,
      ),
      child: Text(
        context.tr('circle_overview.calendar_sync_hint'),
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: context.tokens.textSecondary),
      ),
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
  });

  final String circleId;
  final CalendarSyncCategory category;
  final String label;

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

  @override
  void didUpdateWidget(_CalendarSyncRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A reused State (same slot, new circleId) must not keep showing the
    // previous circle's value while this one's own load is in flight.
    if (oldWidget.circleId != widget.circleId ||
        oldWidget.category != widget.category) {
      _enabled = null;
      _load();
    }
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
      value: _enabled ?? false,
      onChanged: _enabled == null ? (_) {} : _onChanged,
    );
  }
}
