import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/widgets/inline_error.dart';
import 'package:app/core/widgets/labeled_text_field.dart';
import 'package:app/features/circles/domain/medical_options.dart';
import 'package:app/features/circles/presentation/cubit/create_self_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_self_circle_state.dart';
import 'package:app/features/circles/presentation/widgets/circle_step_header.dart';
import 'package:app/features/circles/presentation/widgets/option_chips.dart';
import 'package:app/features/circles/presentation/widgets/step_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Step 3 of 3 of the circle for your own care (PROFILE-03): allergies to
/// medicines and to foods. It is optional, and its main button creates the
/// circle. Needs a [CreateSelfCircleCubit] above it.
class SelfCircleAllergiesScreen extends StatefulWidget {
  const SelfCircleAllergiesScreen({super.key});

  @override
  State<SelfCircleAllergiesScreen> createState() =>
      _SelfCircleAllergiesScreenState();
}

class _SelfCircleAllergiesScreenState extends State<SelfCircleAllergiesScreen> {
  late final TextEditingController _otherMedication;
  late final TextEditingController _otherFood;

  @override
  void initState() {
    super.initState();
    final CreateSelfCircleState state = context
        .read<CreateSelfCircleCubit>()
        .state;
    _otherMedication = TextEditingController(text: state.medicationOther);
    _otherFood = TextEditingController(text: state.foodOther);
  }

  @override
  void dispose() {
    _otherMedication.dispose();
    _otherFood.dispose();
    super.dispose();
  }

  /// Creates the circle and, when it is created, opens the home page. The home
  /// page loads the circles and selects the new one.
  Future<void> _create(
    CreateSelfCircleCubit cubit, {
    bool skipAllergies = false,
  }) async {
    final bool created = await cubit.create(skipAllergies: skipAllergies);
    if (created && mounted) context.go(Routes.today);
  }

  List<ChipOption> _options(String group, List<String> codes) {
    return <ChipOption>[
      for (final String code in <String>[...codes, MedicalOptions.other])
        ChipOption(code, context.tr('medical.$group.$code')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final CreateSelfCircleCubit cubit = context.read<CreateSelfCircleCubit>();
    final TextTheme text = Theme.of(context).textTheme;
    final TextStyle? sectionStyle = text.titleSmall?.copyWith(
      color: AppColors.ink2,
    );
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: BlocConsumer<CreateSelfCircleCubit, CreateSelfCircleState>(
            // The typed texts are cleared in the state when "other" is turned
            // off or "no allergies" is chosen. The fields are cleared with
            // them.
            listenWhen:
                (CreateSelfCircleState before, CreateSelfCircleState after) =>
                    (before.medicationOther != after.medicationOther &&
                        after.medicationOther.isEmpty) ||
                    (before.foodOther != after.foodOther &&
                        after.foodOther.isEmpty),
            listener: (BuildContext context, CreateSelfCircleState state) {
              if (state.medicationOther.isEmpty) _otherMedication.clear();
              if (state.foodOther.isEmpty) _otherFood.clear();
            },
            builder: (BuildContext context, CreateSelfCircleState state) {
              final bool saving = state.status == CreateStatus.saving;
              final String requiredText = context.tr('circles.field_required');
              return Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          CircleStepHeader(
                            step: 3,
                            stepTitle: context.tr('circles.step_allergies'),
                            title: context.tr('circles.allergies_title'),
                            onBack: context.canPop()
                                ? () => context.pop()
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('circles.allergies_hint'),
                            style: sectionStyle,
                          ),
                          const SizedBox(height: 8),
                          OptionChips(
                            options: <ChipOption>[
                              ChipOption(
                                MedicalOptions.none,
                                context.tr('circles.no_allergies'),
                              ),
                            ],
                            isSelected: (String code) => state.noAllergies,
                            onTap: (String code) => cubit.toggleNoAllergies(),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('circles.allergy_medication'),
                            style: sectionStyle,
                          ),
                          const SizedBox(height: 8),
                          OptionChips(
                            options: _options(
                              'medication',
                              MedicalOptions.medications,
                            ),
                            isSelected: state.medication.contains,
                            onTap: cubit.toggleMedication,
                          ),
                          if (state.medication.contains(MedicalOptions.other))
                            ...<Widget>[
                              const SizedBox(height: 12),
                              LabeledTextField(
                                label: context.tr('circles.other_hint'),
                                controller: _otherMedication,
                                maxLength: MedicalOptions.otherMaxLength,
                                textInputAction: TextInputAction.done,
                                onChanged: cubit.medicationOtherChanged,
                                errorText:
                                    state.showErrors &&
                                        state.medicationOther.trim().isEmpty
                                    ? requiredText
                                    : null,
                              ),
                            ],
                          const SizedBox(height: 16),
                          Text(
                            context.tr('circles.allergy_food'),
                            style: sectionStyle,
                          ),
                          const SizedBox(height: 8),
                          OptionChips(
                            options: _options('food', MedicalOptions.foods),
                            isSelected: state.food.contains,
                            onTap: cubit.toggleFood,
                          ),
                          if (state.food.contains(MedicalOptions.other))
                            ...<Widget>[
                              const SizedBox(height: 12),
                              LabeledTextField(
                                label: context.tr('circles.other_hint'),
                                controller: _otherFood,
                                maxLength: MedicalOptions.otherMaxLength,
                                textInputAction: TextInputAction.done,
                                onChanged: cubit.foodOtherChanged,
                                errorText:
                                    state.showErrors &&
                                        state.foodOther.trim().isEmpty
                                    ? requiredText
                                    : null,
                              ),
                            ],
                          if (state.errorKey != null) ...<Widget>[
                            const SizedBox(height: 16),
                            InlineError(messageKey: state.errorKey!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  StepActions(
                    nextLabel: context.tr('circles.create'),
                    isLoading: saving,
                    onNext: () => _create(cubit),
                    onSkip: () => _create(cubit, skipAllergies: true),
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
