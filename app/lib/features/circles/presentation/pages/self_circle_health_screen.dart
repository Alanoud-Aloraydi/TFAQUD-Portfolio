import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/navigation/routers.dart';
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

/// Step 2 of 3 of the circle for your own care (PROFILE-02): blood type and
/// chronic conditions. Both are optional. Needs a [CreateSelfCircleCubit]
/// above it.
class SelfCircleHealthScreen extends StatefulWidget {
  const SelfCircleHealthScreen({super.key});

  @override
  State<SelfCircleHealthScreen> createState() => _SelfCircleHealthScreenState();
}

class _SelfCircleHealthScreenState extends State<SelfCircleHealthScreen> {
  late final TextEditingController _other;

  @override
  void initState() {
    super.initState();
    _other = TextEditingController(
      text: context.read<CreateSelfCircleCubit>().state.conditionOther,
    );
  }

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  void _next(BuildContext context, CreateSelfCircleCubit cubit) {
    if (cubit.continueFromHealth()) {
      context.push(Routes.createSelfCircleAllergies);
    }
  }

  void _skip(BuildContext context, CreateSelfCircleCubit cubit) {
    cubit.skipHealth();
    context.push(Routes.createSelfCircleAllergies);
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
            // The typed text is cleared in the state when "other" is turned
            // off or the step is skipped. The field is cleared with it.
            listenWhen:
                (CreateSelfCircleState before, CreateSelfCircleState after) =>
                    before.conditionOther != after.conditionOther &&
                    after.conditionOther.isEmpty,
            listener: (BuildContext context, CreateSelfCircleState state) =>
                _other.clear(),
            builder: (BuildContext context, CreateSelfCircleState state) {
              return Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          CircleStepHeader(
                            step: 2,
                            stepTitle: context.tr('circles.step_health'),
                            title: context.tr('circles.health_title'),
                            subtitle: context.tr('circles.health_hint'),
                            onBack: context.canPop()
                                ? () => context.pop()
                                : null,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            context.tr('circles.blood_type'),
                            style: sectionStyle,
                          ),
                          const SizedBox(height: 8),
                          OptionChips(
                            options: <ChipOption>[
                              for (final String type
                                  in MedicalOptions.bloodTypes)
                                // The marks keep the sign after the letters
                                // inside the right-to-left chip.
                                ChipOption(type, '‎$type‎'),
                            ],
                            isSelected: (String code) =>
                                code == state.bloodType,
                            onTap: cubit.chooseBloodType,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            context.tr('circles.conditions'),
                            style: sectionStyle,
                          ),
                          const SizedBox(height: 8),
                          OptionChips(
                            options: <ChipOption>[
                              for (final String code in <String>[
                                ...MedicalOptions.conditions,
                                MedicalOptions.none,
                                MedicalOptions.other,
                              ])
                                ChipOption(
                                  code,
                                  context.tr('medical.condition.$code'),
                                ),
                            ],
                            isSelected: state.conditions.contains,
                            onTap: cubit.toggleCondition,
                          ),
                          if (state.conditions.contains(MedicalOptions.other))
                            ...<Widget>[
                              const SizedBox(height: 12),
                              LabeledTextField(
                                label: context.tr('circles.other_hint'),
                                controller: _other,
                                maxLength: MedicalOptions.otherMaxLength,
                                textInputAction: TextInputAction.done,
                                onChanged: cubit.conditionOtherChanged,
                                errorText:
                                    state.showErrors &&
                                        state.conditionOther.trim().isEmpty
                                    ? context.tr('circles.field_required')
                                    : null,
                              ),
                            ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  StepActions(
                    nextLabel: context.tr('circles.next'),
                    onNext: () => _next(context, cubit),
                    onSkip: () => _skip(context, cubit),
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
