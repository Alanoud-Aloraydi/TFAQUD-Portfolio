import 'dart:async';

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/calendar_sync_choices.dart';
import 'package:app/core/widgets/layout/settings_card.dart';
// Its own TextDirection (from intl) would hide Flutter's.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The calendar-sync switches (doses, measurements, appointments) for one
/// circle, as one iOS Settings group: each row an icon square, its name and
/// a switch. No title of its own, so a page can put its own title and the
/// shared [CalendarSyncHint] around it.
class CalendarSyncToggles extends StatelessWidget {
  const CalendarSyncToggles({super.key, required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context) =>
      _CircleCalendar(key: ValueKey<String>(circleId), circleId: circleId);
}

/// One circle in a [CalendarSyncCircleList]: its id, the name shown, and a
/// small picture before the name (the patient's photo).
typedef CalendarSyncCircle = ({String id, String name, Widget? leading});

/// Several circles in one group, each a row that opens in place to its
/// three switches, closed at first: the page stays short, and each row says
/// how many of its switches are on («2 من 3»). As SwiftUI's DisclosureGroup:
/// the chevron points to the end when closed and down when open.
class CalendarSyncCircleList extends StatelessWidget {
  const CalendarSyncCircleList({super.key, required this.circles});

  final List<CalendarSyncCircle> circles;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      children: <Widget>[
        for (final CalendarSyncCircle circle in circles)
          _CircleCalendar(
            key: ValueKey<String>(circle.id),
            circleId: circle.id,
            name: circle.name,
            leading: circle.leading,
          ),
      ],
    );
  }
}

String _labelKey(CalendarSyncCategory category) => switch (category) {
  CalendarSyncCategory.doses => 'circle_overview.calendar_sync_doses',
  CalendarSyncCategory.measurements =>
    'circle_overview.calendar_sync_measurements',
  CalendarSyncCategory.appointments =>
    'circle_overview.calendar_sync_appointments',
};

/// One circle's switches, their values loaded once and kept here, so the
/// row that opens them can say how many are on. With a [name], a row that
/// opens and closes; without one, the switches in their own group.
class _CircleCalendar extends StatefulWidget {
  const _CircleCalendar({
    super.key,
    required this.circleId,
    this.name,
    this.leading,
  });

  final String circleId;
  final String? name;
  final Widget? leading;

  @override
  State<_CircleCalendar> createState() => _CircleCalendarState();
}

class _CircleCalendarState extends State<_CircleCalendar>
    with CalendarSyncChoices<_CircleCalendar> {
  bool _open = false;

  @override
  String get calendarCircleId => widget.circleId;

  List<Widget> _switches(BuildContext context) => <Widget>[
    for (final CalendarSyncCategory category in CalendarSyncCategory.values)
      ToggleRow(
        label: context.tr(_labelKey(category)),
        leading: SettingsIconTile(
          icon: category.icon,
          background: category.tile,
        ),
        value: enabled?[category] ?? false,
        onChanged: (bool value) => unawaited(setChoice(category, value)),
      ),
  ];

  /// «الكل», «2 من 3» or «متوقفة»; nothing while the values load.
  String _summary(BuildContext context) {
    final Map<CalendarSyncCategory, bool>? choices = enabled;
    if (choices == null) return '';
    final int on = choices.values.where((bool value) => value).length;
    if (on == 0) return context.tr('circle_overview.calendar_sync_off');
    if (on == CalendarSyncCategory.values.length) {
      return context.tr('circle_overview.calendar_sync_all');
    }
    return context.tr(
      'circle_overview.calendar_sync_some',
      args: <String>['$on', '${CalendarSyncCategory.values.length}'],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? name = widget.name;
    if (name == null) return SettingsCard(children: _switches(context));
    final bool still = MediaQuery.disableAnimationsOf(context);
    final Duration motion = still ? Duration.zero : AppMotion.disclosure;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final String summary = _summary(context);
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          button: true,
          expanded: _open,
          label: summary.isEmpty ? name : '$name، $summary',
          excludeSemantics: true,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSizes.field),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: <Widget>[
                    if (widget.leading case final Widget leading) ...<Widget>[
                      leading,
                      const SizedBox(width: AppSpacing.md),
                    ],
                    Expanded(child: Text(name, style: text.bodyLarge)),
                    if (summary.isNotEmpty) ...<Widget>[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        summary,
                        style: text.bodyMedium?.copyWith(
                          color: context.tokens.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(width: AppSpacing.sm),
                    // Points to the end closed, down open.
                    AnimatedRotation(
                      turns: _open ? (rtl ? -0.25 : 0.25) : 0,
                      duration: motion,
                      curve: AppMotion.easeOut,
                      child: Icon(
                        AppIcons.forward,
                        size: AppSizes.iconSmall,
                        color: context.tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: motion,
          curve: AppMotion.easeOut,
          alignment: AlignmentDirectional.topStart,
          child: _open
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (final Widget row in _switches(context)) ...<Widget>[
                      const Divider(
                        height: AppSizes.divider,
                        indent: AppSpacing.lg,
                        endIndent: AppSpacing.lg,
                      ),
                      row,
                    ],
                  ],
                )
              : const SizedBox(width: double.infinity),
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
