import 'dart:typed_data';

import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_basic_fields.dart';
import 'package:app/features/medications/presentation/widgets/medication_period_fields.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_field.dart';
import 'package:app/features/medications/presentation/widgets/medication_schedule_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Displays the medication form UI.
class MedicationForm extends StatefulWidget {
  const MedicationForm({super.key, required this.circleId, this.plan});

  final String circleId;
  final MedicationPlan? plan;

  @override
  State<MedicationForm> createState() => _MedicationFormState();
}

class _MedicationFormState extends State<MedicationForm> {
  late final MedicationFormData _data;
  String? _errorKey;
  MedicationFormIssue? _issue;
  bool _dirty = false;
  bool _medicalFieldsDirty = false;
  bool _photoDirty = false;
  Uint8List? _photo;
  bool _photoRemoved = false;
  String? _savedPlanId;

  @override
  void initState() {
    super.initState();
    _data = MedicationFormData(widget.plan);
  }

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.select(
      (MedicationsCubit cubit) =>
          cubit.state.status == MedicationsStatus.saving,
    );
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          automaticallyImplyLeading: false,
          titleSpacing: AppSpacing.lg,
          title: GlassSurface(
            borderRadius: BorderRadius.circular(AppRadius.capsule),
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  TextButton(
                    onPressed: _cancel,
                    child: Text(context.tr('common.cancel')),
                  ),
                  Expanded(
                    child: Text(
                      context.tr(
                        widget.plan == null
                            ? 'medications.add_title'
                            : 'medications.edit_title',
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.xs,
                    ),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppSemanticColors.actionPrimary,
                        foregroundColor: AppSemanticColors.onActionPrimary,
                        minimumSize: const Size(58, 40),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                      ),
                      onPressed: saving ? null : _submit,
                      child: Text(context.tr('medications.save_changes')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MedicationBasicFields(
                data: _data,
                issue: _issue,
                onChanged: _changed,
                photoField: MedicationPhotoField(
                  circleId: widget.circleId,
                  planId: widget.plan?.id,
                  photo: _photo,
                  removed: _photoRemoved,
                  onChanged: (bytes, removed) => setState(() {
                    _photo = bytes;
                    _photoRemoved = removed;
                    _photoDirty = true;
                    _dirty = true;
                    _errorKey = null;
                  }),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              InsetGroup(
                header: context.tr('medications.dose_schedules'),
                children: [
                  for (var index = 0; index < _data.schedules.length; index++)
                    MedicationScheduleEditor(
                      index: index,
                      data: _data.schedules[index],
                      units: _data.form.doseUnits,
                      issue: _issue?.scheduleIndex == index ? _issue : null,
                      startsOn: _data.startsOn,
                      onChanged: _changed,
                      onRemove: _data.schedules.length == 1
                          ? null
                          : () => _removeSchedule(index),
                    ),
                  InsetRow(
                    label: context.tr('medications.add_schedule'),
                    leading: const Icon(AppIcons.plusCircle),
                    onTap: _addSchedule,
                  ),
                ],
              ),
              if (widget.plan != null && _medicalFieldsDirty) ...[
                const SizedBox(height: AppSpacing.xl),
                MedicationEffectiveDateGroup(
                  data: _data,
                  circleId: widget.circleId,
                  onChanged: _changed,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              MedicationInstructionsGroup(data: _data, onChanged: _changed),
              const SizedBox(height: AppSpacing.xl),
              MedicationPeriodFields(
                data: _data,
                issue: _issue,
                onChanged: _changed,
              ),
              if (_errorKey case final error?) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  context.tr(error),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  void _changed() => setState(() {
    _dirty = true;
    _medicalFieldsDirty = true;
    _errorKey = null;
    _issue = null;
  });

  void _addSchedule() {
    _data.addSchedule();
    _changed();
  }

  void _removeSchedule(int index) {
    _data.removeSchedule(index);
    _changed();
  }

  Future<void> _submit() async {
    if (_savedPlanId != null) {
      await _savePhoto(_savedPlanId!);
      return;
    }
    if (widget.plan == null && _data.startsOn.isBefore(riyadhToday())) {
      setState(() => _errorKey = 'medications.start_in_past');
      return;
    }
    final issue = widget.plan != null && !_medicalFieldsDirty
        ? null
        : _data.firstIssue();
    if (issue != null) {
      setState(() => _issue = issue);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) await _focusIssue(issue);
      return;
    }
    final cubit = context.read<MedicationsCubit>();
    var saved = widget.plan != null && !_medicalFieldsDirty;
    if (!saved) {
      final draft = _data.toDraft();
      if (draft == null) return;
      saved = widget.plan == null
          ? await cubit.create(draft)
          : await cubit.revise(widget.plan!, draft);
    }
    if (!mounted) return;
    if (saved) {
      final id =
          widget.plan?.id ??
          (cubit.state.plans.isEmpty ? null : cubit.state.plans.last.id);
      if (id == null) return;
      _savedPlanId = id;
      await _savePhoto(id);
    } else {
      setState(() => _errorKey = cubit.state.messageKey ?? 'error.unknown');
    }
  }

  Future<void> _savePhoto(String planId) async {
    final repository = RepositoryProvider.of<PrivatePhotoRepository>(context);
    final path = ApiEndpoints.medicationPhoto(widget.circleId, planId);
    try {
      if (_photoDirty) {
        if (_photoRemoved) {
          await repository.remove(path);
        } else if (_photo != null) {
          await repository.save(path, _photo!);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _errorKey = 'photos.save_failed');
      return;
    }
    if (!mounted) return;
    _dirty = false;
    context.pop(true);
  }

  Future<void> _focusIssue(MedicationFormIssue issue) async {
    final node = switch (issue.field) {
      MedicationFormField.name => _data.nameFocus,
      MedicationFormField.strength => _data.strengthFocus,
      MedicationFormField.period => _data.periodFocus,
      MedicationFormField.dose =>
        _data.schedules[issue.scheduleIndex!].doseFocus,
      MedicationFormField.weekdays =>
        _data.schedules[issue.scheduleIndex!].weekdaysFocus,
    };
    node.requestFocus();
    final fieldContext = node.context;
    if (fieldContext != null) {
      await Scrollable.ensureVisible(
        fieldContext,
        duration: AppMotion.formScroll,
      );
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await showAppAlert<bool>(
      context,
      title: context.tr('medications.discard_title'),
      message: context.tr('medications.discard_message'),
      actions: [
        AppAlertAction<bool>(label: context.tr('common.cancel'), value: false),
        AppAlertAction<bool>(
          label: context.tr('medications.discard_confirm'),
          value: true,
          destructive: true,
        ),
      ],
    );
    if (discard == true && mounted) {
      _dirty = false;
      context.pop();
    }
  }

  void _cancel() {
    if (_dirty) {
      _confirmDiscard();
    } else {
      context.pop();
    }
  }
}
