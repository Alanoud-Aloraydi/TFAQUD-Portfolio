import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/constants/name_limits.dart';
import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/l10n/medical_texts.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/feedback/inline_error.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/forms/picker_field.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/core/widgets/pickers/city_sheet.dart';
import 'package:app/features/circles/domain/medical_form.dart';
import 'package:app/features/circles/domain/medical_options.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:app/features/circles/presentation/pages/medical_file_edit_screen.dart';
import 'package:app/features/circles/presentation/widgets/read_only_field.dart';
import 'package:app/features/circles/presentation/widgets/time_zone_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The fields and the save button. It is created once the file is loaded and
/// keeps the text controllers, which start from the saved values.
class MedicalFileEditForm extends StatefulWidget {
  const MedicalFileEditForm({
    super.key,
    required this.state,
    required this.savedTo,
    required this.fileRoute,
  });

  final MedicalFileEditState state;

  /// See [MedicalFileEditScreen.savedTo].
  final String? savedTo;

  /// The medical file, for a save with no page under this one.
  final String fileRoute;

  @override
  State<MedicalFileEditForm> createState() => _EditFormState();
}

class _EditFormState extends State<MedicalFileEditForm> {
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
  void didUpdateWidget(MedicalFileEditForm oldWidget) {
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

  Future<void> _pickTimeZone(
    BuildContext context,
    MedicalFileEditCubit cubit,
  ) async {
    final String? picked = await showTimeZoneSheet(
      context,
      selected: widget.state.timeZone,
    );
    if (picked != null) cubit.timeZoneChanged(picked);
  }

  Future<void> _save(BuildContext context, MedicalFileEditCubit cubit) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final GoRouter router = GoRouter.of(context);
    final String saved = context.tr('circles.file_saved');
    final bool ok = await cubit.save();
    if (!ok || !mounted) return;
    AppToast.showText(messenger, saved);
    final String? savedTo = widget.savedTo;
    if (savedTo != null) {
      router.go(savedTo);
    } else if (router.canPop()) {
      router.pop();
    } else {
      router.go(widget.fileRoute);
    }
  }

  /// [otherLabel] names the «أخرى» chip of this group. Under «الحساسية»
  /// the medicines and the foods are one list with no label of their own,
  /// so two bare «أخرى» chips would be impossible to tell apart.
  List<ChipOption> _options(
    String group,
    List<String> codes, {
    String? otherLabel,
  }) {
    return <ChipOption>[
      for (final String code in <String>[...codes, MedicalOptions.other])
        ChipOption(
          code,
          code == MedicalOptions.other && otherLabel != null
              ? otherLabel
              : context.tr('medical.$group.$code'),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final MedicalFileEditCubit cubit = context.read<MedicalFileEditCubit>();
    final MedicalFileEditState state = widget.state;
    final MedicalForm form = state.form;
    final TextTheme text = Theme.of(context).textTheme;
    final String requiredText = context.tr('common.field_required');
    final bool showErrors = state.showErrors;
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (state.namesEditable) ...<Widget>[
                  LabeledTextField(
                    label: context.tr('circles.patient_first_name'),
                    controller: _firstName,
                    maxLength: NameLimits.name,
                    onChanged: cubit.firstNameChanged,
                    errorText: showErrors && state.firstName.trim().isEmpty
                        ? requiredText
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  LabeledTextField(
                    label: context.tr('circles.patient_last_name'),
                    controller: _lastName,
                    maxLength: NameLimits.name,
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
                const SizedBox(height: AppSpacing.lg),
                PickerField(
                  label: context.tr('circles.birth_date'),
                  hint: context.tr('circles.birth_date_hint'),
                  icon: AppIcons.calendar,
                  value: state.birthDate == null
                      ? null
                      : formatBirthDate(context, state.birthDate!),
                  onTap: () => _pickBirthDate(context, cubit),
                  errorText: showErrors && state.birthDate == null
                      ? requiredText
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                PickerField(
                  label: context.tr('circles.city'),
                  hint: context.tr('circles.patient_city_hint'),
                  icon: AppIcons.mapPin,
                  value: state.city,
                  onTap: () => _pickCity(context, cubit),
                  errorText: showErrors && state.city == null
                      ? requiredText
                      : null,
                ),
                // Every Saudi city has one zone; any other city needs one
                // picked here, because all the circle's times follow it.
                if (state.zoneEditable) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  PickerField(
                    label: context.tr('circles.time_zone'),
                    hint: context.tr('circles.time_zone_sheet_title'),
                    icon: AppIcons.clock,
                    value: state.timeZone == null
                        ? null
                        : timeZoneName(state.timeZone!),
                    onTap: () => _pickTimeZone(context, cubit),
                    errorText: showErrors && state.zoneMissing
                        ? requiredText
                        : null,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                InsetText.header(context.tr('circles.blood_type')),
                const SizedBox(height: AppSpacing.sm),
                OptionChips(
                  options: <ChipOption>[
                    for (final String type in MedicalOptions.bloodTypes)
                      ChipOption(type, MedicalTexts.bloodTypeLabel(type)),
                  ],
                  isSelected: (String code) => code == form.bloodType,
                  onTap: cubit.chooseBloodType,
                ),
                const SizedBox(height: AppSpacing.xl),
                InsetText.header(context.tr('circles.conditions')),
                const SizedBox(height: AppSpacing.sm),
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
                if (form.conditions.contains(MedicalOptions.other)) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  LabeledTextField(
                    label: context.tr('circles.other_hint'),
                    controller: _conditionOther,
                    maxLength: MedicalOptions.otherMaxLength,
                    textInputAction: TextInputAction.done,
                    onChanged: cubit.conditionOtherChanged,
                    errorText: showErrors && form.conditionOther.trim().isEmpty
                        ? requiredText
                        : null,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                InsetText.header(context.tr('circles.allergies_title')),
                const SizedBox(height: AppSpacing.sm),
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
                // «لا توجد حساسية» answers the whole section, so the
                // chips under it are only there when it is off. Medicines
                // and foods are one flow: each chip names itself, so a
                // label over each half only pushed them apart.
                if (!form.noAllergies) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  OptionChips(
                    options: _options(
                      'medication',
                      MedicalOptions.medications,
                      otherLabel: context.tr('circles.allergy_other_medicine'),
                    ),
                    isSelected: form.medication.contains,
                    onTap: cubit.toggleMedication,
                  ),
                  if (form.medication.contains(
                    MedicalOptions.other,
                  )) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
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
                  const SizedBox(height: AppSpacing.sm),
                  OptionChips(
                    options: _options(
                      'food',
                      MedicalOptions.foods,
                      otherLabel: context.tr('circles.allergy_other_food'),
                    ),
                    isSelected: form.food.contains,
                    onTap: cubit.toggleFood,
                  ),
                  if (form.food.contains(MedicalOptions.other)) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
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
                ],
                if (state.errorKey != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  InlineError(messageKey: state.errorKey!),
                ],
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PillButton(
          label: context.tr('circles.file_save'),
          isLoading: state.saving,
          onPressed: () => _save(context, cubit),
        ),
      ],
    );
  }
}
