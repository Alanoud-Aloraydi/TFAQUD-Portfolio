import 'dart:async';

import 'package:app/app/router/routers.dart';
import 'package:app/app/services/permissions/app_permission.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/app_calendar.dart';
import 'package:app/core/localization/calendar_texts.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/calendar_scope.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/forms/calendar_sync_choices.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:app/features/auth/presentation/widgets/sign_out_alert.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_reading.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_settings_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_account_legal.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_outlined_danger.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_square_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_text_size_tile.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_weather.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «نوع التاريخ» under «حجم الخط»: two big tiles, هجري and ميلادي, each
/// with today written in it, as the text size has its three.
class SimplifiedCalendarCard extends StatelessWidget {
  const SimplifiedCalendarCard({super.key});

  @override
  Widget build(BuildContext context) {
    final DateCalendar chosen = CalendarScope.of(context);
    return SimplifiedCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SimplifiedStyle.pad,
        vertical: SimplifiedStyle.gap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.tr('calendar.kind'),
            style: SimplifiedStyle.head(SimplifiedStyle.body),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              for (final DateCalendar calendar
                  in DateCalendar.values) ...<Widget>[
                if (calendar != DateCalendar.hijri) const SizedBox(width: 10),
                Expanded(
                  child: SimplifiedCalendarTile(
                    calendar: calendar,
                    selected: calendar == chosen,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// One calendar to pick, «هجري» or «ميلادي», with today's day and month in
/// it; tinted with the thick ink edge when chosen, as a text size tile.
class SimplifiedCalendarTile extends StatelessWidget {
  const SimplifiedCalendarTile({
    super.key,
    required this.calendar,
    required this.selected,
  });

  final DateCalendar calendar;

  /// Whether this is the calendar chosen now.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final DateTime today = PatientClockScope.of(context).today();
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () => AppCalendar.choose(calendar),
        child: Container(
          height: 104,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: simplifiedTextSizeTileDecoration(selected: selected),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                context.tr('calendar.${calendar.name}'),
                style: SimplifiedStyle.head(SimplifiedStyle.body),
              ),
              const SizedBox(height: 4),
              Text(
                calendarDate(context, today, year: false, calendar: calendar),
                textAlign: TextAlign.center,
                style: SimplifiedStyle.text(SimplifiedStyle.caption),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three big tiles, each showing «أ» at the size it gives.
class SimplifiedTextSizeCard extends StatelessWidget {
  const SimplifiedTextSizeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final SimplifiedTextSize selected = context
        .select<SimplifiedSettingsCubit, SimplifiedTextSize>(
          (cubit) => cubit.state.textSize,
        );
    return SimplifiedCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SimplifiedStyle.pad,
        vertical: SimplifiedStyle.gap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.tr('simplified_mode.text_size'),
            style: SimplifiedStyle.head(SimplifiedStyle.body),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              for (final SimplifiedTextSize size
                  in SimplifiedTextSize.values) ...<Widget>[
                if (size != SimplifiedTextSize.normal)
                  const SizedBox(width: 10),
                Expanded(
                  child: SimplifiedTextSizeTile(
                    size: size,
                    selected: size == selected,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class SimplifiedSignOutButton extends StatelessWidget {
  const SimplifiedSignOutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthErrorState) {
          AppToast.show(context, state.messageKey, kind: ToastKind.error);
        }
        if (state is AuthSignedOutState) {
          if (!state.serverConfirmed) {
            AppToast.show(
              context,
              'auth.sign_out_local_only',
              kind: ToastKind.error,
            );
          }
          context.go(Routes.auth);
        }
      },
      builder: (context, state) => SimplifiedOutlinedDanger(
        label: context.tr('simplified_mode.sign_out'),
        busy: state is AuthLoadingState,
        filled: true,
        onPressed: () => _signOut(context),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    if (await askSignOutConfirmation(context) != true) return;
    if (!context.mounted) return;
    await context.read<AuthCubit>().signOut();
  }
}

/// The circle's medicines, measurement times and appointments on the
/// phone's own calendar: one switch, in this mode's sizes. The same choice
/// the detailed mode keeps, through the same [CalendarSync]; off until
/// chosen.
class SimplifiedCalendarSyncCard extends StatefulWidget {
  const SimplifiedCalendarSyncCard({super.key, required this.circleId});

  final String circleId;

  @override
  State<SimplifiedCalendarSyncCard> createState() =>
      _SimplifiedCalendarSyncCardState();
}

class _SimplifiedCalendarSyncCardState extends State<SimplifiedCalendarSyncCard>
    with CalendarSyncChoices<SimplifiedCalendarSyncCard> {
  @override
  String get calendarCircleId => widget.circleId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SimplifiedCard(
          padding: const EdgeInsets.symmetric(horizontal: SimplifiedStyle.pad),
          child: SimplifiedCalendarRow(
            label: context.tr('simplified_mode.calendar_switch'),
            value: enabled ?? false,
            onChanged: enabled == null
                ? null
                : (bool value) => unawaited(setChoice(value)),
          ),
        ),
        if (blocked)
          const SimplifiedPermissionDenied(
            messageKey: 'circle_overview.calendar_access_denied',
          )
        else if (enabled == true && access == AppPermission.partial)
          const SimplifiedPermissionDenied(
            messageKey: 'circle_overview.calendar_access_partial',
          )
        else
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: 8,
              start: SimplifiedStyle.pad,
              end: SimplifiedStyle.pad,
            ),
            child: Text(
              context.tr('simplified_mode.calendar_text'),
              style: SimplifiedStyle.text(SimplifiedStyle.caption),
            ),
          ),
      ],
    );
  }
}

/// The calendar row: a calendar square, what goes on the calendar, a switch.
class SimplifiedCalendarRow extends StatelessWidget {
  const SimplifiedCalendarRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => SimplifiedSwitchRow(
    icon: ScheduleIcons.calendar,
    background: AppSettingsTileColors.appointments,
    label: label,
    value: value,
    onChanged: onChanged,
  );
}
