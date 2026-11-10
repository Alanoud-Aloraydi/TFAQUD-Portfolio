import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/utils/text_limits.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/date_picker_sheet.dart';
import 'package:app/core/widgets/pickers/time_picker_sheet.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/appointment_companions_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Displays the appointment form page UI.
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
  static const _specialties = [
    'internal',
    'diabetes',
    'cardiology',
    'eyes',
    'dental',
    'neurology',
    'other',
  ];
  AppointmentKind _kind = AppointmentKind.followUp;
  String _specialty = 'diabetes';

  /// A new visit starts on the patient's today.
  late DateTime _date = PatientClockScope.of(context).today();
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  String _remoteMethod = 'video';
  final Set<String> _companionIds = <String>{};
  final _place = TextEditingController();
  final _otherSpecialty = TextEditingController();
  final _otherKind = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  String? _errorKey;

  @override
  void dispose() {
    _place.dispose();
    _otherSpecialty.dispose();
    _otherKind.dispose();
    super.dispose();
  }

  void _fill(CareAppointment value) {
    if (_initialized) return;
    _initialized = true;
    _specialty = _specialties.contains(value.specialty)
        ? value.specialty
        : 'other';
    _otherSpecialty.text = _specialty == 'other' ? value.specialty : '';
    _kind = value.kind;
    _otherKind.text = value.otherKind ?? '';
    _date = value.scheduledOn;
    final parts = value.time.split(':');
    _time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    _place.text = value.place ?? '';
    _remoteMethod = value.remoteMethod ?? 'video';
    _companionIds
      ..clear()
      ..addAll(value.companions.map((item) => item.id));
  }

  /// Checks the form, then adds the appointment (or changes [value]) and
  /// leaves with `true`; the cubit's message key shows when the server says no.
  Future<void> _save(CareAppointment? value) async {
    if (_saving) return;
    if (_specialty == 'other' && _otherSpecialty.text.trim().isEmpty) {
      setState(() => _errorKey = 'appointments.specialty_required');
      return;
    }
    if (_kind == AppointmentKind.other && _otherKind.text.trim().isEmpty) {
      setState(() => _errorKey = 'appointments.kind_required');
      return;
    }
    if (_companionIds.isEmpty) {
      setState(() => _errorKey = 'appointments.companion_required');
      return;
    }
    if (_kind != AppointmentKind.remote && _place.text.trim().isEmpty) {
      setState(() => _errorKey = 'appointments.place_required');
      return;
    }
    final draft = AppointmentDraft(
      specialty: _specialty == 'other'
          ? _otherSpecialty.text.trim()
          : _specialty,
      kind: _kind,
      otherKind: _kind == AppointmentKind.other ? _otherKind.text.trim() : null,
      scheduledOn: _date,
      time:
          '${_time.hour.toString().padLeft(2, '0')}:'
          '${_time.minute.toString().padLeft(2, '0')}',
      place: _kind == AppointmentKind.remote ? null : _place.text.trim(),
      remoteMethod: _kind == AppointmentKind.remote ? _remoteMethod : null,
      companionAccountIds: _companionIds.toList(),
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
      context.pop(true);
    } else {
      setState(() {
        _saving = false;
        _errorKey = errorKey;
      });
    }
  }

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
              AppointmentsLoadStatus.loading =>
                const CircularProgressIndicator(),
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
                semanticLabel: context.tr('appointments.specialty'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _choices(
                      _specialties,
                      _specialty,
                      (value) => setState(() {
                        _specialty = value;
                        _errorKey = null;
                      }),
                      (value) => context.tr('appointments.specialties.$value'),
                    ),
                    if (_specialty == 'other')
                      TextField(
                        controller: _otherSpecialty,
                        maxLength: 80,
                        inputFormatters: const [CodePointLengthFormatter(80)],
                        textAlign: TextAlign.start,
                        onChanged: (_) => setState(() => _errorKey = null),
                        decoration: InputDecoration(
                          labelText: context.tr(
                            'appointments.custom_specialty',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              InsetBlock(
                semanticLabel: context.tr('appointments.type'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _choices(
                      AppointmentKind.values.map((kind) => kind.name).toList(),
                      _kind.name,
                      (value) => setState(() {
                        _kind = AppointmentKind.values.byName(value);
                        _errorKey = null;
                      }),
                      (value) => context.tr('appointments.kinds.$value'),
                    ),
                    if (_kind == AppointmentKind.other)
                      TextField(
                        controller: _otherKind,
                        maxLength: 80,
                        inputFormatters: const [CodePointLengthFormatter(80)],
                        textAlign: TextAlign.start,
                        onChanged: (_) => setState(() => _errorKey = null),
                        decoration: InputDecoration(
                          labelText: context.tr('appointments.custom_kind'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          InsetGroup(
            header: context.tr('appointments.time_place_group'),
            children: [
              InsetRow(
                label: context.tr('appointments.date'),
                value: appointmentDate(context, _date),
                showChevron: true,
                onTap: () async {
                  final today = PatientClockScope.of(context).today();
                  final selected = await showTafaqodDateSheet(
                    context,
                    title: context.tr('appointments.date'),
                    initialDate: _date.isBefore(today) ? today : _date,
                    firstDate: today,
                    lastDate: DateTime(today.year + 5, 12, 31),
                  );
                  if (selected != null && mounted) {
                    setState(() => _date = selected);
                  }
                },
              ),
              InsetRow(
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
                    setState(() => _time = selected);
                  }
                },
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
                InsetBlock(
                  semanticLabel: context.tr('appointments.place'),
                  child: TextField(
                    controller: _place,
                    textAlign: TextAlign.start,
                    maxLength: 160,
                    inputFormatters: const [CodePointLengthFormatter(160)],
                    decoration: InputDecoration(
                      labelText: context.tr('appointments.place'),
                      hintText: context.tr('appointments.place_hint'),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          InsetGroup(
            header: context.tr('appointments.companion'),
            footer: context.tr('appointments.companion_hint'),
            children: [
              InsetBlock(
                child: companions.loading
                    ? const Center(child: CircularProgressIndicator())
                    : companions.errorKey != null
                    ? TextButton(
                        onPressed: () => context
                            .read<AppointmentCompanionsCubit>()
                            .load(widget.circleId),
                        child: Text(context.tr(companions.errorKey!)),
                      )
                    : companions.companions.isEmpty
                    ? Text(context.tr('appointments.no_companions'))
                    : Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final item in companions.companions)
                            FilterChip(
                              avatar: PersonPhoto(
                                name: item.name,
                                photoPath: ApiEndpoints.memberPhoto(
                                  widget.circleId,
                                  item.id,
                                ),
                                avatarCode: item.avatarCode,
                                size: 20,
                              ),
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(item.name),
                                  if (_companionIds.contains(item.id)) ...[
                                    const SizedBox(width: AppSpacing.xs),
                                    const Icon(AppIcons.check, size: 16),
                                  ],
                                ],
                              ),
                              showCheckmark: false,
                              selected: _companionIds.contains(item.id),
                              onSelected: (selected) => setState(() {
                                if (selected) {
                                  _companionIds.add(item.id);
                                } else if (_companionIds.length > 1) {
                                  _companionIds.remove(item.id);
                                }
                              }),
                            ),
                        ],
                      ),
              ),
            ],
          ),
          if (_errorKey != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              context.tr(_errorKey!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _choices(
    List<String> options,
    String? selected,
    ValueChanged<String> onSelected,
    String Function(String) label,
  ) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      for (final value in options)
        ChoiceChip(
          label: Text(label(value)),
          selected: selected == value,
          onSelected: (_) => onSelected(value),
        ),
    ],
  );
}
