import 'package:app/core/widgets/labeled_text_field.dart';
import 'package:app/core/widgets/pill_button.dart';
import 'package:app/features/circles/domain/circle_label.dart';
import 'package:app/features/circles/presentation/circle_flow_routes.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/widgets/birth_date_sheet.dart';
import 'package:app/features/circles/presentation/widgets/circle_label_picker.dart';
import 'package:app/features/circles/presentation/widgets/circle_step_header.dart';
import 'package:app/features/circles/presentation/widgets/city_sheet.dart';
import 'package:app/features/circles/presentation/widgets/picker_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Step 1 of 3 of the circle for a patient who does not use the app
/// (PROFILE-01B): the names of the patient, the birth date, the word the circle
/// is named with, and the city. Needs a [CreateCircleCubit] of the patient flow
/// above it.
class PatientCircleBasicsScreen extends StatefulWidget {
  const PatientCircleBasicsScreen({super.key});

  @override
  State<PatientCircleBasicsScreen> createState() =>
      _PatientCircleBasicsScreenState();
}

class _PatientCircleBasicsScreenState extends State<PatientCircleBasicsScreen> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _customLabel;

  @override
  void initState() {
    super.initState();
    final CreateCircleState state = context.read<CreateCircleCubit>().state;
    _firstName = TextEditingController(text: state.patientFirstName);
    _lastName = TextEditingController(text: state.patientLastName);
    _customLabel = TextEditingController(text: state.customLabel);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _customLabel.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate(
    BuildContext context,
    CreateCircleCubit cubit,
    DateTime? current,
  ) async {
    final DateTime? picked = await showBirthDateSheet(
      context,
      selected: current,
    );
    if (picked != null) cubit.birthDateChanged(picked);
  }

  Future<void> _pickCity(
    BuildContext context,
    CreateCircleCubit cubit,
    String? current,
  ) async {
    final String? picked = await showCitySheet(
      context,
      selected: current,
      titleKey: 'circles.patient_city_sheet_title',
    );
    if (picked != null) cubit.cityChanged(picked);
  }

  void _next(BuildContext context, CreateCircleCubit cubit) {
    final CircleLabel label = cubit.state.label;
    final bool ok = cubit.continueFromPatientBasics(
      labelName: context.tr('circles.label.${label.name}'),
    );
    if (ok) context.push(cubit.flow.healthRoute);
  }

  @override
  Widget build(BuildContext context) {
    final CreateCircleCubit cubit = context.read<CreateCircleCubit>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: BlocBuilder<CreateCircleCubit, CreateCircleState>(
            builder: (BuildContext context, CreateCircleState state) {
              final String requiredText = context.tr('circles.field_required');
              return Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          CircleStepHeader(
                            step: 1,
                            stepTitle: context.tr('circles.step_basics'),
                            title: context.tr('circles.patient_title'),
                            onBack: context.canPop()
                                ? () => context.pop()
                                : null,
                          ),
                          const SizedBox(height: 24),
                          LabeledTextField(
                            label: context.tr('circles.patient_first_name'),
                            controller: _firstName,
                            maxLength: CreateCircleCubit.maxNameLength,
                            onChanged: cubit.patientFirstNameChanged,
                            errorText:
                                state.showErrors &&
                                    state.patientFirstName.trim().isEmpty
                                ? requiredText
                                : null,
                          ),
                          const SizedBox(height: 16),
                          LabeledTextField(
                            label: context.tr('circles.patient_last_name'),
                            controller: _lastName,
                            maxLength: CreateCircleCubit.maxNameLength,
                            textInputAction: TextInputAction.done,
                            onChanged: cubit.patientLastNameChanged,
                            errorText:
                                state.showErrors &&
                                    state.patientLastName.trim().isEmpty
                                ? requiredText
                                : null,
                          ),
                          const SizedBox(height: 16),
                          PickerField(
                            label: context.tr('circles.birth_date'),
                            hint: context.tr('circles.birth_date_hint'),
                            icon: Icons.calendar_today_outlined,
                            value: state.birthDate == null
                                ? null
                                : formatBirthDate(context, state.birthDate!),
                            onTap: () => _pickBirthDate(
                              context,
                              cubit,
                              state.birthDate,
                            ),
                            errorText:
                                state.showErrors && state.birthDate == null
                                ? requiredText
                                : null,
                          ),
                          const SizedBox(height: 24),
                          CircleLabelPicker(
                            selected: state.label,
                            onSelected: cubit.chooseLabel,
                            customController: _customLabel,
                            onCustomChanged: cubit.customLabelChanged,
                            hint: circleLabelHint(
                              context,
                              label: state.label,
                              customLabel: state.customLabel,
                              firstName: state.patientFirstName,
                            ),
                            customError:
                                state.showErrors &&
                                    state.customLabel.trim().isEmpty
                                ? requiredText
                                : null,
                          ),
                          const SizedBox(height: 24),
                          PickerField(
                            label: context.tr('circles.city'),
                            hint: context.tr('circles.patient_city_hint'),
                            icon: Icons.location_on_outlined,
                            value: state.city,
                            onTap: () => _pickCity(context, cubit, state.city),
                            errorText: state.showErrors && state.city == null
                                ? requiredText
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PillButton(
                    label: context.tr('circles.next'),
                    onPressed: () => _next(context, cubit),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
