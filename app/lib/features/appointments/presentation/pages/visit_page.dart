import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/visit_paper.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_state.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/visit_state.dart';
import 'package:app/features/appointments/presentation/widgets/show_visit_edit_sheet.dart';
import 'package:app/features/appointments/presentation/widgets/visit_fill_once.dart';
import 'package:app/features/appointments/presentation/widgets/visit_title_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Displays the visit page UI.
class VisitPage extends StatelessWidget {
  const VisitPage({
    super.key,
    required this.appointmentId,
    required this.canManage,
  });

  final String appointmentId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppointmentsCubit>().state;
    CareAppointment? appointment;
    for (final item in state.appointments) {
      if (item.id == appointmentId) appointment = item;
    }
    final visit = context.watch<VisitCubit>().state;
    final Widget page = Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        titleSpacing: AppSpacing.lg,
        title: const VisitTitleBar(),
      ),
      body: state.status == AppointmentsLoadStatus.loading || visit.loading
          ? const LoadingNote()
          : visit.loadFailed
          ? Center(
              child: TextButton(
                onPressed: context.read<VisitCubit>().load,
                child: Text(context.tr(visit.errorKey ?? 'error.unknown')),
              ),
            )
          : appointment == null
          ? Center(
              child: TextButton(
                onPressed: () => context.read<AppointmentsCubit>().load(
                  context.read<VisitCubit>().circleId,
                ),
                child: Text(context.tr(state.errorKey ?? 'error.not_found')),
              ),
            )
          : _body(context, appointment, visit),
    );
    // Reached from «حضرت», it opens its form once the visit is read.
    return canManage ? VisitFillOnce(child: page) : page;
  }

  Widget _body(
    BuildContext context,
    CareAppointment appointment,
    VisitState state,
  ) {
    final paper = state.paper;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appointmentTitle(context, appointment),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                '${appointmentDate(context, appointment.scheduledOn)}، '
                '${clockText(appointment.time)}',
                style: Theme.of(context).textTheme.bodyMedium,
                semanticsLabel: spoken(
                  '${appointmentDate(context, appointment.scheduledOn)}، '
                  '${clockText(appointment.time)}',
                ),
              ),
              Text(
                '${appointment.kind == AppointmentKind.remote ? context.tr('appointments.${appointment.remoteMethod}') : appointment.place ?? ''}، '
                '${appointmentCompanionLine(context, appointment)}',
                style: Theme.of(context).textTheme.bodySmall,
                semanticsLabel: spoken(
                  '${appointment.kind == AppointmentKind.remote ? context.tr('appointments.${appointment.remoteMethod}') : appointment.place ?? ''}، '
                  '${appointmentCompanionLine(context, appointment)}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        InsetGroup(
          children: [
            InsetBlock(
              child: _field(
                context,
                'appointments.visit_summary',
                paper?.summary,
              ),
            ),
            InsetBlock(
              child: _field(
                context,
                'appointments.visit_recommendations',
                paper?.recommendations,
              ),
            ),
            InsetBlock(
              child: _field(
                context,
                'appointments.visit_follow_up',
                paper?.followUp,
              ),
            ),
          ],
        ),
        if (canManage) ...[
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => context.push<bool>(
              Routes.newAppointment(context.read<VisitCubit>().circleId),
            ),
            icon: const Icon(CupertinoIcons.calendar),
            label: Text(context.tr('appointments.add_follow_up_appointment')),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (paper?.hasAudio == true)
          Material(
            color: AppSemanticColors.surfaceContent,
            borderRadius: BorderRadius.circular(AppRadius.m),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  IconButton(
                    onPressed: state.playing
                        ? context.read<VisitCubit>().stopAudio
                        : context.read<VisitCubit>().playAudio,
                    icon: Icon(
                      state.playing
                          ? CupertinoIcons.pause_fill
                          : CupertinoIcons.play_fill,
                    ),
                    tooltip: context.tr(
                      state.playing
                          ? 'appointments.audio_stop'
                          : 'appointments.audio_play',
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        for (var index = 0; index < 28; index++)
                          Expanded(
                            child: Container(
                              height: 6.0 + (index * 7 % 13),
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: AppSemanticColors.borderControlBase,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(_duration(state.audioSeconds)),
                ],
              ),
            ),
          ),
        if (state.recording) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr(
              'appointments.recording_time',
              args: [_duration(state.recordedSeconds)],
            ),
          ),
        ],
        if (state.errorKey != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr(state.errorKey!),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (canManage) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.saving || state.recording
                      ? null
                      : () => _edit(context, paper),
                  icon: const Icon(AppIcons.pencil),
                  label: Text(context.tr('appointments.edit_visit')),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.saving
                      ? null
                      : state.recording
                      ? context.read<VisitCubit>().stopAndSaveRecording
                      : context.read<VisitCubit>().startRecording,
                  icon: Icon(
                    state.recording
                        ? CupertinoIcons.stop_fill
                        : CupertinoIcons.mic,
                  ),
                  label: Text(
                    context.tr(
                      state.recording
                          ? 'appointments.audio_save'
                          : 'appointments.audio_record',
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (state.recording)
            TextButton(
              onPressed: context.read<VisitCubit>().cancelRecording,
              child: Text(context.tr('common.cancel')),
            ),
          if (paper?.hasAudio == true && !state.recording)
            TextButton(
              onPressed: state.saving ? null : () => _removeAudio(context),
              child: Text(context.tr('appointments.audio_remove')),
            ),
        ],
      ],
    );
  }

  // One stop for the reader: the heading and its answer together.
  Widget _field(BuildContext context, String key, String? value) =>
      MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(key),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value?.isNotEmpty == true
                  ? value!
                  : context.tr('appointments.visit_empty'),
            ),
          ],
        ),
      );

  String _duration(int? seconds) {
    if (seconds == null) return '--:--';
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _edit(BuildContext context, VisitPaper? paper) =>
      showVisitEditSheet(context, paper);

  Future<void> _removeAudio(BuildContext context) async {
    final remove = await showAppAlert<bool>(
      context,
      title: context.tr('appointments.audio_remove_confirm'),
      actions: [
        AppAlertAction<bool>(label: context.tr('common.cancel'), value: false),
        AppAlertAction<bool>(
          label: context.tr('appointments.audio_remove'),
          value: true,
          destructive: true,
        ),
      ],
    );
    if (remove == true && context.mounted) {
      context.read<VisitCubit>().removeAudio();
    }
  }
}
