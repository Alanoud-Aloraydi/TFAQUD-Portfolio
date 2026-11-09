import 'dart:async';

import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/compact_status_badge.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/core/widgets/navigation/white_filter_menu.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

String appointmentTitle(BuildContext context, CareAppointment value) {
  const presets = {
    'internal',
    'diabetes',
    'cardiology',
    'eyes',
    'dental',
    'neurology',
  };
  if (!presets.contains(value.specialty)) return value.specialty;
  return '${context.tr('appointments.clinic')} '
      '${context.tr('appointments.specialties.${value.specialty}')}';
}

String appointmentKindTitle(BuildContext context, CareAppointment value) =>
    value.kind == AppointmentKind.other
    ? value.otherKind ?? context.tr('appointments.kinds.other')
    : context.tr('appointments.kinds.${value.kind.name}');

String appointmentCompanionNames(BuildContext context, CareAppointment value) =>
    value.companions
        .map((companion) => companion.name)
        .join(context.tr('appointments.companion_separator'));

String appointmentDate(BuildContext context, DateTime date) =>
    '${context.tr('common.weekdays.${date.weekday}')} '
    '${date.day} ${context.tr('circles.months.${date.month}')}';

String appointmentTime(BuildContext context, String value) {
  final parts = value.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  return '${hour % 12 == 0 ? 12 : hour % 12}:'
      '${minute.toString().padLeft(2, '0')} '
      '${context.tr(hour < 12 ? 'common.am' : 'common.pm')}';
}

/// Displays the appointment plan section UI.
class AppointmentPlanSection extends StatelessWidget {
  const AppointmentPlanSection({
    super.key,
    required this.circleId,
    required this.canManage,
    required this.header,
  });

  final String circleId;
  final bool canManage;
  final Widget header;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppointmentsCubit>().state;
    final now = riyadhNow();
    final values =
        state.appointments
            .where(
              (item) =>
                  item.status == AppointmentStatus.scheduled &&
                  !item.scheduledAt.isBefore(now),
            )
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return ListView(
      padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
      children: [
        header,
        const SizedBox(height: AppSpacing.lg),
        if (state.errorKey != null &&
            state.status != AppointmentsLoadStatus.failure)
          Text(context.tr(state.errorKey!)),
        if (state.status == AppointmentsLoadStatus.loading && values.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (state.status == AppointmentsLoadStatus.failure)
          TextButton(
            onPressed: () => context.read<AppointmentsCubit>().load(circleId),
            child: Text(context.tr(state.errorKey ?? 'error.unknown')),
          )
        else if (values.isEmpty)
          EmptyStateNote(
            context.tr('appointments.no_upcoming'),
            actionLabel: canManage ? context.tr('add.appointment') : null,
            onAction: canManage ? () => _addAppointment(context) : null,
          )
        else
          for (final value in values) ...[
            AppointmentCard(
              value: value,
              circleId: circleId,
              canManage: canManage,
              showRelativeDate: true,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }

  Future<void> _addAppointment(BuildContext context) async {
    final saved = await context.push<bool>(Routes.newAppointment(circleId));
    if (saved == true && context.mounted) {
      unawaited(context.read<AppointmentsCubit>().load(circleId));
    }
  }
}

/// Displays the appointment card UI.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.value,
    required this.circleId,
    required this.canManage,
    this.showRelativeDate = false,
  });

  final CareAppointment value;
  final String circleId;
  final bool canManage;
  final bool showRelativeDate;

  @override
  Widget build(BuildContext context) {
    final remote = value.kind == AppointmentKind.remote;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceContent,
        border: Border.all(color: AppSemanticColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppSemanticColors.surfaceContent,
                  child: Icon(
                    remote ? CupertinoIcons.videocam : CupertinoIcons.calendar,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointmentTitle(context, value),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(appointmentKindTitle(context, value)),
                    ],
                  ),
                ),
                CompactStatusBadge(
                  text: context.tr(
                    showRelativeDate
                        ? _relativeDateKey(value.scheduledOn)
                        : value.status == AppointmentStatus.scheduled &&
                              value.scheduledAt.isBefore(riyadhNow())
                        ? 'appointments.status.unconfirmed'
                        : 'appointments.status.${value.status.name}',
                    args: showRelativeDate
                        ? ['${scheduleDay(value.scheduledOn).difference(riyadhToday()).inDays}']
                        : null,
                  ),
                  background: AppSemanticColors.surfaceContent,
                  foreground: AppSemanticColors.textPrimary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppSemanticColors.surfaceContent,
                border: Border.all(color: AppSemanticColors.borderSubtle),
                borderRadius: BorderRadius.circular(AppRadius.field),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${appointmentDate(context, value.scheduledOn)} · '
                      '${appointmentTime(context, value.time)}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      remote
                          ? context.tr('appointments.${value.remoteMethod}')
                          : value.place ?? '',
                    ),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final companion in value.companions)
                          PersonPhoto(
                            name: companion.name,
                            photoPath: ApiEndpoints.memberPhoto(
                              circleId,
                              companion.id,
                            ),
                            avatarCode: companion.avatarCode,
                            size: 20,
                          ),
                        Text(
                          context.tr(
                            'appointments.companion_name',
                            args: [appointmentCompanionNames(context, value)],
                          ),
                        ),
                      ],
                    ),
                    if (value.createdByName case final name?) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.tr('appointments.added_by', args: [name]),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (value.updatedByName case final name?
                        when name != value.createdByName) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.tr('appointments.last_edited_by', args: [name]),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (value.status == AppointmentStatus.scheduled &&
                !value.scheduledAt.isBefore(riyadhNow())) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.tr('appointments.appears_today'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (value.status == AppointmentStatus.completed)
              TextButton.icon(
                onPressed: () async {
                  await context.push<void>(
                    Routes.appointmentVisit(circleId, value.id),
                    extra: canManage,
                  );
                  if (context.mounted) {
                    context.read<AppointmentsCubit>().load(circleId);
                  }
                },
                icon: const Icon(CupertinoIcons.doc_text),
                label: Text(context.tr('appointments.visit_title')),
              ),
            if (canManage && value.status == AppointmentStatus.scheduled)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // The outlined capsule with a pencil, as every edit.
                    OutlinedButton.icon(
                      onPressed: () async {
                        final changed = await context.push<bool>(
                          Routes.editAppointment(circleId, value.id),
                        );
                        if (changed == true && context.mounted) {
                          context.read<AppointmentsCubit>().load(circleId);
                        }
                      },
                      icon: const Icon(AppIcons.pencil),
                      label: Text(context.tr('appointments.edit')),
                    ),
                    if (!value.scheduledAt.isAfter(riyadhNow()))
                      TextButton(
                        onPressed: () =>
                            _status(context, AppointmentStatus.completed),
                        child: Text(context.tr('appointments.mark_completed')),
                      ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppSemanticColors.statusError,
                      ),
                      onPressed: () =>
                          _status(context, AppointmentStatus.cancelled),
                      child: Text(
                        context.tr('appointments.cancel_appointment'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _status(BuildContext context, AppointmentStatus status) async {
    final confirmed = await showAppAlert<bool>(
      context,
      title: context.tr(
        status == AppointmentStatus.completed
            ? 'appointments.confirm_completed'
            : 'appointments.confirm_cancelled',
      ),
      actions: [
        AppAlertAction<bool>(label: context.tr('common.cancel'), value: false),
        AppAlertAction<bool>(
          label: context.tr('appointments.confirm'),
          value: true,
          primary: status == AppointmentStatus.completed,
          destructive: status == AppointmentStatus.cancelled,
        ),
      ],
    );
    if (confirmed == true && context.mounted) {
      context.read<AppointmentsCubit>().setStatus(value, status);
    }
  }

  String _relativeDateKey(DateTime date) {
    final days = scheduleDay(date).difference(riyadhToday()).inDays;
    if (days == 0) return 'appointments.today';
    if (days == 1) return 'appointments.tomorrow';
    if (days == 2) return 'appointments.in_two_days';
    return 'appointments.after_days';
  }
}

/// Displays the appointment record section UI.
class AppointmentRecordSection extends StatefulWidget {
  const AppointmentRecordSection({
    super.key,
    required this.circleId,
    required this.canManage,
    required this.header,
  });

  final String circleId;
  final bool canManage;
  final Widget header;

  @override
  State<AppointmentRecordSection> createState() =>
      _AppointmentRecordSectionState();
}

class _AppointmentRecordSectionState extends State<AppointmentRecordSection> {
  static const _filters = ['all', 'upcoming', 'previous'];
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppointmentsCubit>().state;
    final now = riyadhNow();
    final values = state.appointments.where((item) {
      final upcoming =
          item.status == AppointmentStatus.scheduled &&
          !item.scheduledAt.isBefore(now);
      return _filter == 'all' || (_filter == 'upcoming') == upcoming;
    }).toList()..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return ListView(
      padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
      children: [
        widget.header,
        const SizedBox(height: AppSpacing.md),
        if (state.errorKey != null &&
            state.status != AppointmentsLoadStatus.failure)
          Text(context.tr(state.errorKey!)),
        WhiteFilterMenu<String>(
          glass: true,
          options: {
            for (final key in _filters)
              key: context.tr('appointments.filters.$key'),
          },
          selected: _filter,
          onChanged: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.status == AppointmentsLoadStatus.loading && values.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (state.status == AppointmentsLoadStatus.failure)
          TextButton(
            onPressed: () =>
                context.read<AppointmentsCubit>().load(widget.circleId),
            child: Text(context.tr(state.errorKey ?? 'error.unknown')),
          )
        else if (values.isEmpty)
          EmptyStateNote(
            context.tr('appointments.no_records'),
            actionLabel: widget.canManage
                ? context.tr('add.appointment')
                : null,
            onAction: widget.canManage ? () => _addAppointment(context) : null,
          )
        else
          for (final value in values) ...[
            AppointmentCard(
              value: value,
              circleId: widget.circleId,
              canManage: widget.canManage,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }

  Future<void> _addAppointment(BuildContext context) async {
    final saved = await context.push<bool>(
      Routes.newAppointment(widget.circleId),
    );
    if (saved == true && context.mounted) {
      unawaited(context.read<AppointmentsCubit>().load(widget.circleId));
    }
  }
}

/// Displays the appointment today row UI.
class AppointmentTodayRow extends StatelessWidget {
  const AppointmentTodayRow({super.key, required this.value});
  final CareAppointment value;

  @override
  Widget build(BuildContext context) => TodayRowCard(
    child: Row(
      children: [
        const Icon(CupertinoIcons.calendar),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(appointmentTitle(context, value)),
              Text(
                context.tr(
                  'appointments.companion_name',
                  args: [appointmentCompanionNames(context, value)],
                ),
              ),
            ],
          ),
        ),
        Text(appointmentTime(context, value.time)),
      ],
    ),
  );
}
