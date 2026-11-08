import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/feedback/inline_error.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/features/circles/presentation/circle_creation_finish.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/widgets/birth_date_sheet.dart';
import 'package:app/features/circles/presentation/widgets/circle_step_header.dart';
import 'package:app/features/circles/presentation/widgets/city_sheet.dart';
import 'package:app/features/circles/presentation/widgets/picker_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The circle for a patient who does not use the app (PROFILE-01B) on one
/// page: the names of the patient, the birth date and the city. Nobody names
/// the circle: everyone sees «دائرة» and the patient's first name, and the
/// page shows it as it is typed. The health condition and allergies are filled
/// later in the medical file. Needs a [CreateCircleCubit] of the patient flow
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

  @override
  void initState() {
    super.initState();
    final CreateCircleState state = context.read<CreateCircleCubit>().state;
    _firstName = TextEditingController(text: state.patientFirstName);
    _lastName = TextEditingController(text: state.patientLastName);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
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

  Future<void> _create(BuildContext context, CreateCircleCubit cubit) async {
    final bool ok = cubit.continueFromPatientBasics(
      sharedName: context.tr(
        'circles.shared_name',
        args: <String>[cubit.state.patientFirstName.trim()],
      ),
    );
    if (ok) await createCircleAndOpen(context, cubit);
  }

  @override
  Widget build(BuildContext context) {
    final CreateCircleCubit cubit = context.read<CreateCircleCubit>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: BlocBuilder<CreateCircleCubit, CreateCircleState>(
            builder: (BuildContext context, CreateCircleState state) {
              final String requiredText = context.tr('circles.field_required');
              return Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          CircleStepHeader(
                            title: context.tr('circles.patient_title'),
                            subtitle: context.tr('circles.patient_subtitle'),
                            onBack: context.canPop()
                                ? () => context.pop()
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.xl),
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
                          const SizedBox(height: AppSpacing.lg),
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
                          const SizedBox(height: AppSpacing.lg),
                          PickerField(
                            label: context.tr('circles.birth_date'),
                            hint: context.tr('circles.birth_date_hint'),
                            icon: AppIcons.calendar,
                            value: state.birthDate == null
                                ? null
                                : formatBirthDate(context, state.birthDate!),
                            onTap: () =>
                                _pickBirthDate(context, cubit, state.birthDate),
                            errorText:
                                state.showErrors && state.birthDate == null
                                ? requiredText
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          InsetText.header(context.tr('circles.circle_name')),
                          const SizedBox(height: AppSpacing.sm),
                          InsetText.note(
                            state.patientFirstName.trim().isEmpty
                                ? context.tr('circles.shared_name_hint')
                                : context.tr(
                                    'circles.name_preview',
                                    args: <String>[
                                      context.tr(
                                        'circles.shared_name',
                                        args: <String>[
                                          state.patientFirstName.trim(),
                                        ],
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          PickerField(
                            label: context.tr('circles.city'),
                            hint: context.tr('circles.patient_city_hint'),
                            icon: AppIcons.mapPin,
                            value: state.city,
                            onTap: () => _pickCity(context, cubit, state.city),
                            errorText: state.showErrors && state.city == null
                                ? requiredText
                                : null,
                          ),
                          if (state.errorKey != null) ...<Widget>[
                            const SizedBox(height: AppSpacing.lg),
                            InlineError(messageKey: state.errorKey!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PillButton(
                    label: context.tr('circles.create'),
                    isLoading: state.status == CreateStatus.saving,
                    onPressed: () => _create(context, cubit),
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
