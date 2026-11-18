import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/core/widgets/forms/field_with_error.dart';
import 'package:app/core/widgets/layout/inset_block.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/time_picker_sheet.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/appointment_reminder_lead.dart';
import 'package:app/features/appointments/presentation/cubit/appointment_companions_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_state.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_companion_chips.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_dates_row.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_kind_choices.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_lead_row.dart';
import 'package:app/features/appointments/presentation/widgets/companion_hint.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Adds or edits a visit: its kind, clinic, date, time, place and companions.
class AppointmentFormPage extends StatefulWidget {
  const AppointmentFormPage({
    super.key,
    required this.circleId,
    this.appointmentId,
  });

  final String circleId;
  final String? appointmentId;

  @override
  State<AppointmentFormPage> createState() => _AppointmentFormPageState();
}

class _AppointmentFormPageState extends State<AppointmentFormPage> {
  AppointmentKind _kind = AppointmentKind.followUp;

  /// The visit days, oldest first, all in «أيام المواعيد»: a new visit
  /// starts on the patient's today; an edited one is its own day alone.
  late List<DateTime> _days = <DateTime>[PatientClockScope.of(context).today()];
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  String _remoteMethod = 'video';
  final Set<String> _companionIds = <String>{};

  /// How long before the visit its near reminder comes.
  int _lead = defaultAppointmentLead;
  final _place = TextEditingController();
  final _clinic = TextEditingController();
  final _otherKind = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  String? _errorKey;

  @override
  void dispose() {
    _place.dispose();
    _clinic.dispose();
    _otherKind.dispose();
    super.dispose();
  }

  void _fill(CareAppointment value) {
    if (_initialized) return;
    _initialized = true;
    _clinic.text = value.specialty ?? '';
    _kind = value.kind;
    _otherKind.text = value.otherKind ?? '';
    _days = <DateTime>[value.scheduledOn];
    final parts = value.time.split(':');
    _time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    _place.text = value.place ?? '';
    _remoteMethod = value.remoteMethod ?? 'video';
    _lead = value.reminderLeadMinutes;
    _companionIds
      ..clear()
      ..addAll(value.companions.map((item) => item.id));
  }

  /// Checks the form, then adds the appointment (or changes [value]) and
  /// leaves with `true`; the cubit's message key shows when the server says no.
  Future<void> _save(CareAppointment? value) async {
    if (_saving) return;
    if (_kind == AppointmentKind.other && _otherKind.text.trim().isEmpty) {
      setState(() => _errorKey = 'appointments.kind_required');
      return;
    }
    if (_kind != AppointmentKind.remote && _place.text.trim().isEmpty) {
      setState(() => _errorKey = 'appointments.place_required');
      return;
    }
    if (_days.isEmpty) {
      setState(() => _errorKey = 'appointments.days_required');
      return;
    }
    final draft = AppointmentDraft(
      specialty: _clinic.text.trim().isEmpty ? null : _clinic.text.trim(),
      kind: _kind,
      otherKind: _kind == AppointmentKind.other ? _otherKind.text.trim() : null,
      scheduledOn: _days.first,
      time:
          '${_time.hour.toString().padLeft(2, '0')}:'
          '${_time.minute.toString().padLeft(2, '0')}',
      place: _kind == AppointmentKind.remote ? null : _place.text.trim(),
      remoteMethod: _kind == AppointmentKind.remote ? _remoteMethod : null,
      companionAccountIds: _companionIds.toList(),
      reminderLeadMinutes: _lead,
      alsoOn: _days.skip(1).toList(),
    );
    if (wallClockAt(
      draft.scheduledOn,
      draft.time,
    ).isBefore(PatientClockScope.of(context).now())) {
      setState(() => _errorKey = 'appointments.time_in_past');
      return;
    }
    setState(() {
      _saving = true;
      _errorKey = null;
    });
    final cubit = context.read<AppointmentsCubit>();
    final errorKey = value == null
        ? await cubit.create(widget.circleId, draft)
        : await cubit.revise(widget.circleId, value, draft);
    if (!mounted) return;
    if (errorKey == null) {
      AppToast.show(context, 'toast.appointment_saved');
      context.pop(true);
      return;
    }
    setState(() => _saving = false);
    // The visit's time is checked again by the server; anything else is
    // about no one field: a short message.
    if (errorKey == 'appointments.time_in_past') {
      setState(() => _errorKey = errorKey);
    } else {
      AppToast.show(context, errorKey, kind: ToastKind.error);
    }
  }

  /// The error under the field it is about ([key]), while it is the one.
  String? _fieldError(String key) => _errorKey == key ? context.tr(key) : null;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppointmentsCubit>().state;
    final companions = context.watch<AppointmentCompanionsCubit>().state;
    CareAppointment? appointment;
    if (widget.appointmentId != null) {
      for (final item in state.appointments) {
        if (item.id == widget.appointmentId) appointment = item;
      }
      if (appointment != null) _fill(appointment);
      if (appointment == null) {
        return Scaffold(
          body: Center(
            child: switch (state.status) {
              AppointmentsLoadStatus.initial ||
              AppointmentsLoadStatus.loading => const LoadingNote(),
              AppointmentsLoadStatus.failure => TextButton(
                onPressed: () =>
                    context.read<AppointmentsCubit>().load(widget.circleId),
                child: Text(context.tr(state.errorKey ?? 'error.unknown')),
              ),
              AppointmentsLoadStatus.ready => Text(
                context.tr('error.resource_not_found'),
              ),
            },
          ),
        );
      }
    }
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
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(context.tr('common.cancel')),
                ),
                Expanded(
                  child: Text(
                    context.tr(
                      appointment == null
                          ? 'appointments.new'
                          : 'appointments.edit',
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                  child: FilledButton(
                    onPressed: _saving ? null : () => _save(appointment),
                    child: Text(context.tr('appointments.save')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          InsetGroup(
            header: context.tr('appointments.appointment_group'),
            children: [
              InsetBlock(
                semanticLabel: context.tr('appointments.type'),
                child: AppointmentKindChoices(
                  selected: _kind,
                  onSelected: (kind) => setState(() {
                    _kind = kind;
                    _errorKey = null;
                  }),
                ),
              ),
              if (_kind == AppointmentKind.other)
                FieldWithError(
                  error: _fieldError('appointments.kind_required'),
                  child: InsetTextRow(
                    label: context.tr('appointments.custom_kind'),
                    controller: _otherKind,
                    maxLength: 80,
                    onChanged: (_) => setState(() => _errorKey = null),
                  ),
                ),
              InsetTextRow(
                label: context.tr('appointments.clinic_field'),
                hint: context.tr('appointments.clinic_hint'),
                controller: _clinic,
                maxLength: 80,
                onChanged: (_) {},
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          InsetGroup(
            header: context.tr('appointments.time_place_group'),
            children: [
              FieldWithError(
                error: _fieldError('appointments.days_required'),
                child: AppointmentDatesRow(
                  dates: _days,
                  single: widget.appointmentId != null,
                  onChanged: (value) => setState(() => _days = value),
                ),
              ),
              FieldWithError(
                error: _fieldError('appointments.time_in_past'),
                child: InsetRow(
                  label: context.tr('appointments.time'),
                  value: timeOfDayText(_time),
                  showChevron: true,
                  onTap: () async {
                    final selected = await showTafaqodTimeSheet(
                      context,
                      title: context.tr('appointments.time'),
                      initialTime: _time,
                    );
                    if (selected != null && mounted) {
                      setState(() {
                        _time = selected;
                        _errorKey = null;
                      });
                    }
                  },
                ),
              ),
              AppointmentLeadRow(
                minutes: _lead,
                time: _time,
                onChanged: (int value) => setState(() => _lead = value),
              ),
              if (_kind == AppointmentKind.remote)
                InsetBlock(
                  semanticLabel: context.tr('appointments.remote_method'),
                  child: GlassSegmentedControl<String>(
                    segments: {
                      'video': context.tr('appointments.video'),
                      'phone': context.tr('appointments.phone'),
                    },
                    selected: _remoteMethod,
                    onChanged: (value) => setState(() => _remoteMethod = value),
                  ),
                )
              else
                FieldWithError(
                  error: _fieldError('appointments.place_required'),
                  child: InsetTextRow(
                    label: context.tr('appointments.place'),
                    hint: context.tr('appointments.place_hint'),
                    controller: _place,
                    maxLength: 160,
                    maxLines: 3,
                    onChanged: (_) => setState(() => _errorKey = null),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          InsetGroup(
            header: context.tr('appointments.companion'),
            footer: companionHint(context, companions, _companionIds),
            children: [
              AppointmentCompanionChips(
                circleId: widget.circleId,
                state: companions,
                chosen: _companionIds,
                onToggle: (String id, bool selected) => setState(() {
                  selected ? _companionIds.add(id) : _companionIds.remove(id);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
