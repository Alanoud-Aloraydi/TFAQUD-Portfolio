import 'package:app/core/navigation/routers.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/visit_paper.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_sections.dart';
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        titleSpacing: AppSpacing.lg,
        title: GlassSurface(
          borderRadius: BorderRadius.circular(AppRadius.capsule),
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: context.pop,
                  icon: const Icon(CupertinoIcons.arrow_right),
                  label: Text(context.tr('common.back')),
                ),
                Expanded(
                  child: Text(
                    context.tr('appointments.visit_title'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 88),
              ],
            ),
          ),
        ),
      ),
      body: state.status == AppointmentsLoadStatus.loading || visit.loading
          ? const Center(child: CircularProgressIndicator())
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
        Text(
          appointmentTitle(context, appointment),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          '${appointmentDate(context, appointment.scheduledOn)} · '
          '${appointmentTime(context, appointment.time)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          '${appointment.kind == AppointmentKind.remote ? context.tr('appointments.${appointment.remoteMethod}') : appointment.place ?? ''} · '
          '${context.tr('appointments.companion_name', args: [appointment.companionName])}',
          style: Theme.of(context).textTheme.bodySmall,
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

  Widget _field(BuildContext context, String key, String? value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(context.tr(key), style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: AppSpacing.xs),
      Text(
        value?.isNotEmpty == true
            ? value!
            : context.tr('appointments.visit_empty'),
      ),
    ],
  );

  String _duration(int? seconds) {
    if (seconds == null) return '--:--';
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _edit(BuildContext context, VisitPaper? paper) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => BlocProvider.value(
          value: context.read<VisitCubit>(),
          child: _VisitEditSheet(paper: paper),
        ),
      );

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

/// Renders the visit edit sheet element of visit page.
class _VisitEditSheet extends StatefulWidget {
  const _VisitEditSheet({required this.paper});

  final VisitPaper? paper;

  @override
  State<_VisitEditSheet> createState() => _VisitEditSheetState();
}

class _VisitEditSheetState extends State<_VisitEditSheet> {
  late final _summary = TextEditingController(text: widget.paper?.summary);
  late final _recommendations = TextEditingController(
    text: widget.paper?.recommendations,
  );
  late final _followUp = TextEditingController(text: widget.paper?.followUp);

  @override
  void dispose() {
    _summary.dispose();
    _recommendations.dispose();
    _followUp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .82,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('appointments.edit_visit'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              InsetGroup(
                header: context.tr('appointments.visit_summary'),
                children: [
                  InsetBlock(child: _paperInput(context, _summary, 2000)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              InsetGroup(
                header: context.tr('appointments.visit_recommendations'),
                children: [
                  InsetBlock(
                    child: _paperInput(context, _recommendations, 2000),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              InsetGroup(
                header: context.tr('appointments.visit_follow_up'),
                children: [
                  InsetBlock(child: _paperInput(context, _followUp, 500)),
                ],
              ),
              if (context.watch<VisitCubit>().state.errorKey case final error?)
                Text(
                  context.tr(error),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: context.watch<VisitCubit>().state.saving
                    ? null
                    : () async {
                        final saved = await context.read<VisitCubit>().save(
                          VisitPaperDraft(
                            summary: _summary.text,
                            recommendations: _recommendations.text,
                            followUp: _followUp.text,
                          ),
                        );
                        if (saved && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                child: Text(context.tr('appointments.save')),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _paperInput(
    BuildContext context,
    TextEditingController controller,
    int limit,
  ) => Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: TextField(
      controller: controller,
      maxLength: limit,
      minLines: 2,
      maxLines: 4,
      textAlign: TextAlign.start,
      decoration: InputDecoration(
        hintText: context.tr('appointments.visit_empty'),
        border: InputBorder.none,
        counterText: '',
      ),
    ),
  );
}
