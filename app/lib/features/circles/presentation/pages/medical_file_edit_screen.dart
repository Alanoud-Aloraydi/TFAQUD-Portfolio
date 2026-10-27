import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/widgets/inline_error.dart';
import 'package:app/core/widgets/labeled_text_field.dart';
import 'package:app/core/widgets/loading_widget.dart';
import 'package:app/core/widgets/pill_button.dart';
import 'package:app/core/widgets/step_header.dart';
import 'package:app/features/circles/domain/medical_form.dart';
import 'package:app/features/circles/domain/medical_options.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:app/features/circles/presentation/widgets/birth_date_sheet.dart';
import 'package:app/features/circles/presentation/widgets/city_sheet.dart';
import 'package:app/features/circles/presentation/widgets/medical_texts.dart';
import 'package:app/features/circles/presentation/widgets/option_chips.dart';
import 'package:app/features/circles/presentation/widgets/picker_field.dart';
import 'package:app/features/circles/presentation/widgets/read_only_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The edit page of the medical file (CIRCLE-05, "تعديل"): the names of a
/// patient without an account, the birth date, the city, the blood type, the
/// chronic conditions and the allergies. Needs a [MedicalFileEditCubit] above
/// it. It closes with `true` when something was saved.
class MedicalFileEditScreen extends StatelessWidget {
  const MedicalFileEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MedicalFileEditCubit cubit = context.read<MedicalFileEditCubit>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: BlocConsumer<MedicalFileEditCubit, MedicalFileEditState>(
            listenWhen:
                (MedicalFileEditState before, MedicalFileEditState after) =>
                    after.sessionEnded && !before.sessionEnded,
            listener: (BuildContext context, MedicalFileEditState state) =>
                context.go(Routes.auth),
            builder: (BuildContext context, MedicalFileEditState state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  StepHeader(
                    title: context.tr('circles.file_edit_title'),
                    onBack: context.canPop()
                        ? () => context.pop()
                        : () => context.go(Routes.medicalFile(cubit.circleId)),
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _body(context, cubit, state)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    MedicalFileEditCubit cubit,
    MedicalFileEditState state,
  ) {
    switch (state.status) {
      case MedicalFileEditStatus.loading:
        return const LoadingWidget();
      case MedicalFileEditStatus.failure:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                context.tr(state.messageKey ?? 'error.unknown'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: cubit.load,
                child: Text(context.tr('auth.retry')),
              ),
            ],
          ),
        );
      case MedicalFileEditStatus.ready:
        return _EditForm(state: state);
    }
  }
}

/// The fields and the save button. It is created once the file is loaded and
/// keeps the text controllers, which start from the saved values.
class _EditForm extends StatefulWidget {
  const _EditForm({required this.state});

  final MedicalFileEditState state;

  @override
  State<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<_EditForm> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _conditionOther;
  late final TextEditingController _medicationOther;
  late final TextEditingController _foodOther;

  @override
  void initState() {
    super.initState();
    final MedicalFileEditState state = widget.state;
    _firstName = TextEditingController(text: state.firstName);
    _lastName = TextEditingController(text: state.lastName);
    _conditionOther = TextEditingController(text: state.form.conditionOther);
    _medicationOther = TextEditingController(text: state.form.medicationOther);
    _foodOther = TextEditingController(text: state.form.foodOther);
  }

  @override
  void didUpdateWidget(_EditForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The typed text of "other" is cleared in the state when "other" is turned
    // off or "no allergies" is chosen. The fields are cleared with it.
    final MedicalForm form = widget.state.form;
    if (form.conditionOther.isEmpty) _conditionOther.clear();
    if (form.medicationOther.isEmpty) _medicationOther.clear();
    if (form.foodOther.isEmpty) _foodOther.clear();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _conditionOther.dispose();
    _medicationOther.dispose();
    _foodOther.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate(
    BuildContext context,
    MedicalFileEditCubit cubit,
  ) async {
    final DateTime? picked = await showBirthDateSheet(
      context,
      selected: widget.state.birthDate,
    );
    if (picked != null) cubit.birthDateChanged(picked);
  }

  Future<void> _pickCity(
    BuildContext context,
    MedicalFileEditCubit cubit,
  ) async {
    final String? picked = await showCitySheet(
      context,
      selected: widget.state.city,
      titleKey: 'circles.patient_city_sheet_title',
    );
    if (picked != null) cubit.cityChanged(picked);
  }

  Future<void> _save(BuildContext context, MedicalFileEditCubit cubit) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final GoRouter router = GoRouter.of(context);
    final String saved = context.tr('circles.file_saved');
    final bool ok = await cubit.save();
    if (!ok || !mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(saved)));
    if (router.canPop()) {
      router.pop(true);
    } else {
      router.go(Routes.medicalFile(cubit.circleId));
    }
  }

  List<ChipOption> _options(String group, List<String> codes) {
    return <ChipOption>[
      for (final String code in <String>[...codes, MedicalOptions.other])
        ChipOption(code, context.tr('medical.$group.$code')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final MedicalFileEditCubit cubit = context.read<MedicalFileEditCubit>();
    final MedicalFileEditState state = widget.state;
    final MedicalForm form = state.form;
    final TextTheme text = Theme.of(context).textTheme;
    final TextStyle? sectionStyle = text.titleSmall?.copyWith(
      color: AppColors.ink2,
    );
    final String requiredText = context.tr('circles.field_required');
    final bool showErrors = state.showErrors;
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (state.namesEditable) ...<Widget>[
                  LabeledTextField(
                    label: context.tr('circles.patient_first_name'),
                    controller: _firstName,
                    maxLength: MedicalFileEditCubit.maxNameLength,
                    onChanged: cubit.firstNameChanged,
                    errorText: showErrors && state.firstName.trim().isEmpty
                        ? requiredText
                        : null,
                  ),
                  const SizedBox(height: 16),
                  LabeledTextField(
                    label: context.tr('circles.patient_last_name'),
                    controller: _lastName,
                    maxLength: MedicalFileEditCubit.maxNameLength,
                    onChanged: cubit.lastNameChanged,
                    textInputAction: TextInputAction.done,
                    errorText: showErrors && state.lastName.trim().isEmpty
                        ? requiredText
                        : null,
                  ),
                ] else
                  ReadOnlyField(
                    label: context.tr('circles.name'),
                    note: context.tr('circles.file_name_note'),
                    child: Text(
                      state.file!.patient.fullName,
                      style: text.bodyLarge,
                    ),
                  ),
                const SizedBox(height: 16),
                PickerField(
                  label: context.tr('circles.birth_date'),
                  hint: context.tr('circles.birth_date_hint'),
                  icon: Icons.calendar_today_outlined,
                  value: state.birthDate == null
                      ? null
                      : formatBirthDate(context, state.birthDate!),
                  onTap: () => _pickBirthDate(context, cubit),
                  errorText: showErrors && state.birthDate == null
                      ? requiredText
                      : null,
                ),
                const SizedBox(height: 16),
                PickerField(
                  label: context.tr('circles.city'),
                  hint: context.tr('circles.patient_city_hint'),
                  icon: Icons.location_on_outlined,
                  value: state.city,
                  onTap: () => _pickCity(context, cubit),
                  errorText: showErrors && state.city == null
                      ? requiredText
                      : null,
                ),
                const SizedBox(height: 24),
                Text(context.tr('circles.blood_type'), style: sectionStyle),
                const SizedBox(height: 8),
                OptionChips(
                  options: <ChipOption>[
                    for (final String type in MedicalOptions.bloodTypes)
                      ChipOption(type, MedicalTexts.bloodTypeLabel(type)),
                  ],
                  isSelected: (String code) => code == form.bloodType,
                  onTap: cubit.chooseBloodType,
                ),
                const SizedBox(height: 24),
                Text(context.tr('circles.conditions'), style: sectionStyle),
                const SizedBox(height: 8),
                OptionChips(
                  options: <ChipOption>[
                    for (final String code in <String>[
                      ...MedicalOptions.conditions,
                      MedicalOptions.none,
                      MedicalOptions.other,
                    ])
                      ChipOption(code, context.tr('medical.condition.$code')),
                  ],
                  isSelected: form.conditions.contains,
                  onTap: cubit.toggleCondition,
                ),
                if (form.conditions.contains(MedicalOptions.other))
                  ...<Widget>[
                    const SizedBox(height: 12),
                    LabeledTextField(
                      label: context.tr('circles.other_hint'),
                      controller: _conditionOther,
                      maxLength: MedicalOptions.otherMaxLength,
                      textInputAction: TextInputAction.done,
                      onChanged: cubit.conditionOtherChanged,
                      errorText:
                          showErrors && form.conditionOther.trim().isEmpty
                          ? requiredText
                          : null,
                    ),
                  ],
                const SizedBox(height: 24),
                Text(context.tr('circles.allergies_title'), style: sectionStyle),
                const SizedBox(height: 8),
                OptionChips(
                  options: <ChipOption>[
                    ChipOption(
                      MedicalOptions.none,
                      context.tr('circles.no_allergies'),
                    ),
                  ],
                  isSelected: (String code) => form.noAllergies,
                  onTap: (String code) => cubit.toggleNoAllergies(),
                ),
                const SizedBox(height: 16),
                Text(context.tr('circles.allergy_medication'), style: sectionStyle),
                const SizedBox(height: 8),
                OptionChips(
                  options: _options('medication', MedicalOptions.medications),
                  isSelected: form.medication.contains,
                  onTap: cubit.toggleMedication,
                ),
                if (form.medication.contains(MedicalOptions.other))
                  ...<Widget>[
                    const SizedBox(height: 12),
                    LabeledTextField(
                      label: context.tr('circles.other_hint'),
                      controller: _medicationOther,
                      maxLength: MedicalOptions.otherMaxLength,
                      textInputAction: TextInputAction.done,
                      onChanged: cubit.medicationOtherChanged,
                      errorText:
                          showErrors && form.medicationOther.trim().isEmpty
                          ? requiredText
                          : null,
                    ),
                  ],
                const SizedBox(height: 16),
                Text(context.tr('circles.allergy_food'), style: sectionStyle),
                const SizedBox(height: 8),
                OptionChips(
                  options: _options('food', MedicalOptions.foods),
                  isSelected: form.food.contains,
                  onTap: cubit.toggleFood,
                ),
                if (form.food.contains(MedicalOptions.other))
                  ...<Widget>[
                    const SizedBox(height: 12),
                    LabeledTextField(
                      label: context.tr('circles.other_hint'),
                      controller: _foodOther,
                      maxLength: MedicalOptions.otherMaxLength,
                      textInputAction: TextInputAction.done,
                      onChanged: cubit.foodOtherChanged,
                      errorText: showErrors && form.foodOther.trim().isEmpty
                          ? requiredText
                          : null,
                    ),
                  ],
                if (state.errorKey != null) ...<Widget>[
                  const SizedBox(height: 16),
                  InlineError(messageKey: state.errorKey!),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        PillButton(
          label: context.tr('circles.file_save'),
          isLoading: state.saving,
          onPressed: () => _save(context, cubit),
        ),
      ],
    );
  }
}
