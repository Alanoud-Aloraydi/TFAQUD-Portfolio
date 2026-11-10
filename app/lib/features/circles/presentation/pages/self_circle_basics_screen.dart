import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/feedback/inline_error.dart';
import 'package:app/core/widgets/forms/birth_date_city_fields.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/circles/presentation/circle_creation_finish.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/widgets/account_name_field.dart';
import 'package:app/features/circles/presentation/widgets/already_has_circle_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The circle for the person's own care (PROFILE-01) on one page: only its
/// name. Their name, birth date and city come from the account (onboarding
/// saved them); an account made before onboarding asked for them is asked
/// here.
/// The health condition and allergies are filled later in the medical file.
/// Needs a [CreateCircleCubit] of the self flow above it.
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

  Future<void> _create(BuildContext context, CreateCircleCubit cubit) =>
      createCircleAndOpen(
        context,
        cubit,
        presetName: context.tr('circles.preset.${cubit.state.namePreset.name}'),
      );

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
              if (state.alreadyHasCircle) return const AlreadyHasCircleView();
              final String requiredText = context.tr('common.field_required');
              return Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          StepHeader(
                            title: context.tr('circles.self_title'),
                            subtitle: context.tr('circles.self_subtitle'),
                            onBack: context.canPop()
                                ? () => context.pop()
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          InsetText.header(context.tr('circles.circle_name')),
                          const SizedBox(height: AppSpacing.sm),
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
                          if (state.namePreset == NamePreset.other) ...<Widget>[
                            const SizedBox(height: AppSpacing.md),
                            LabeledTextField(
                              label: context.tr('circles.custom_name'),
                              controller: _customName,
                              maxLength: CreateCircleCubit.maxCustomNameLength,
                              textInputAction: TextInputAction.done,
                              onChanged: cubit.customNameChanged,
                              errorText:
                                  state.showErrors &&
                                      state.customName.trim().isEmpty
                                  ? requiredText
                                  : null,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          InsetText.note(context.tr('circles.name_hint')),
                          if (state.accountLoad ==
                              AccountLoad.failed) ...<Widget>[
                            const SizedBox(height: AppSpacing.lg),
                            AccountLoadFailed(onRetry: cubit.loadAccount),
                          ],
                          // Only an account that has not saved them yet:
                          // onboarding asks for both now.
                          if (state.asksBasics &&
                              !state.waitingForAccount) ...<Widget>[
                            const SizedBox(height: AppSpacing.xl),
                            BirthDateCityFields(
                              birthDate: state.birthDate,
                              city: state.city,
                              onBirthDate: cubit.birthDateChanged,
                              onCity: cubit.cityChanged,
                              showErrors: state.showErrors,
                            ),
                          ],
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
                    isLoading: state.busy,
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
