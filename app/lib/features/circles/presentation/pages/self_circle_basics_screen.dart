import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/widgets/labeled_text_field.dart';
import 'package:app/core/widgets/pill_button.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/widgets/account_name_field.dart';
import 'package:app/features/circles/presentation/widgets/already_has_circle_view.dart';
import 'package:app/features/circles/presentation/widgets/birth_date_sheet.dart';
import 'package:app/features/circles/presentation/widgets/circle_step_header.dart';
import 'package:app/features/circles/presentation/widgets/city_sheet.dart';
import 'package:app/features/circles/presentation/widgets/option_chips.dart';
import 'package:app/features/circles/presentation/widgets/picker_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Step 1 of 3 of the circle for your own care (PROFILE-01): the name of the
/// circle, the birth date and the city. Needs a [CreateCircleCubit] of the
/// self flow above it.
class SelfCircleBasicsScreen extends StatefulWidget {
  const SelfCircleBasicsScreen({super.key});

  @override
  State<SelfCircleBasicsScreen> createState() => _SelfCircleBasicsScreenState();
}

class _SelfCircleBasicsScreenState extends State<SelfCircleBasicsScreen> {
  late final TextEditingController _customName;

  @override
  void initState() {
    super.initState();
    _customName = TextEditingController(
      text: context.read<CreateCircleCubit>().state.customName,
    );
  }

  @override
  void dispose() {
    _customName.dispose();
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
    final String? picked = await showCitySheet(context, selected: current);
    if (picked != null) cubit.cityChanged(picked);
  }

  void _next(BuildContext context, CreateCircleCubit cubit) {
    final NamePreset preset = cubit.state.namePreset;
    final bool ok = cubit.continueFromBasics(
      presetName: context.tr('circles.preset.${preset.name}'),
    );
    if (ok) context.push(Routes.createSelfCircleHealth);
  }

  @override
  Widget build(BuildContext context) {
    final CreateCircleCubit cubit = context.read<CreateCircleCubit>();
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: BlocBuilder<CreateCircleCubit, CreateCircleState>(
            builder: (BuildContext context, CreateCircleState state) {
              if (state.alreadyHasCircle) return const AlreadyHasCircleView();
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
                            title: context.tr('circles.self_title'),
                            onBack: context.canPop()
                                ? () => context.pop()
                                : null,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            context.tr('circles.circle_name'),
                            style: text.titleSmall?.copyWith(
                              color: AppColors.ink2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          OptionChips(
                            options: <ChipOption>[
                              for (final NamePreset preset in NamePreset.values)
                                ChipOption(
                                  preset.name,
                                  context.tr('circles.preset.${preset.name}'),
                                ),
                            ],
                            isSelected: (String code) =>
                                code == state.namePreset.name,
                            onTap: (String code) => cubit.choosePreset(
                              NamePreset.values.byName(code),
                            ),
                          ),
                          if (state.namePreset == NamePreset.other)
                            ...<Widget>[
                              const SizedBox(height: 12),
                              LabeledTextField(
                                label: context.tr('circles.custom_name'),
                                controller: _customName,
                                maxLength:
                                    CreateCircleCubit.maxCustomNameLength,
                                textInputAction: TextInputAction.done,
                                onChanged: cubit.customNameChanged,
                                errorText:
                                    state.showErrors &&
                                        state.customName.trim().isEmpty
                                    ? requiredText
                                    : null,
                              ),
                            ],
                          const SizedBox(height: 8),
                          Text(
                            context.tr('circles.name_hint'),
                            style: text.bodySmall?.copyWith(
                              color: AppColors.ink3,
                            ),
                          ),
                          const SizedBox(height: 24),
                          AccountNameField(
                            state: state,
                            onRetry: cubit.loadAccount,
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
                          const SizedBox(height: 16),
                          PickerField(
                            label: context.tr('circles.city'),
                            hint: context.tr('circles.city_hint'),
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
