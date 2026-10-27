import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/pill_button.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_basic_fields.dart';
import 'package:app/features/medications/presentation/widgets/medication_period_fields.dart';
import 'package:app/features/medications/presentation/widgets/medication_schedule_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MedicationForm extends StatefulWidget {
  const MedicationForm({super.key, this.plan});

  final MedicationPlan? plan;

  @override
  State<MedicationForm> createState() => _MedicationFormState();
}

class _MedicationFormState extends State<MedicationForm> {
  late final MedicationFormData _data;
  String? _errorKey;

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr(
            widget.plan == null
                ? 'medications.add_title'
                : 'medications.edit_title',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _title('medications.basic_details'),
          MedicationBasicFields(data: _data, onChanged: _changed),
          const SizedBox(height: AppSpacing.xl),
          _title('medications.treatment_period'),
          MedicationPeriodFields(data: _data, onChanged: _changed),
          const SizedBox(height: AppSpacing.xl),
          _title('medications.dose_schedules'),
          for (var index = 0; index < _data.schedules.length; index++) ...[
            MedicationScheduleEditor(
              index: index,
              data: _data.schedules[index],
              unit: _data.form.doseUnit,
              onChanged: _changed,
              onRemove: _data.schedules.length == 1
                  ? null
                  : () => _removeSchedule(index),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          OutlinedButton.icon(
            onPressed: _addSchedule,
            icon: const Icon(Icons.add),
            label: Text(context.tr('medications.add_schedule')),
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
          PillButton(
            label: context.tr('medications.save'),
            onPressed: _submit,
            isLoading: saving,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _title(String key) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Text(context.tr(key), style: Theme.of(context).textTheme.titleLarge),
  );

  void _changed() => setState(() => _errorKey = null);

  void _addSchedule() {
    _data.addSchedule();
    _changed();
  }

  void _removeSchedule(int index) {
    _data.removeSchedule(index);
    _changed();
  }

  Future<void> _submit() async {
    final draft = _data.toDraft();
    if (draft == null) {
      setState(() => _errorKey = 'medications.form_invalid');
      return;
    }
    final cubit = context.read<MedicationsCubit>();
    final saved = widget.plan == null
        ? await cubit.create(draft)
        : await cubit.revise(widget.plan!, draft);
    if (!mounted) return;
    if (saved) {
      context.pop(true);
    } else {
      setState(() => _errorKey = cubit.state.messageKey ?? 'error.unknown');
    }
  }
}
