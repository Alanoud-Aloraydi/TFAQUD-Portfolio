import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/feedback/inline_error.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/forms/option_chips.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/features/circles/presentation/circle_creation_finish.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/widgets/account_name_field.dart';
import 'package:app/features/circles/presentation/widgets/already_has_circle_view.dart';
import 'package:app/features/circles/presentation/widgets/birth_date_city_fields.dart';
import 'package:app/features/circles/presentation/widgets/circle_step_header.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The page after the patient agreed to a request (PROFILE-01C): the name
/// comes from the account, and the patient names the circle for themself
/// with the same chips as their own circle («رعايتي», «صحتي», «دائرتي» or a
/// typed name). Only they see that name; the others see «دائرة» and the
/// patient's name. The birth date and city come from the account; an account
/// made before onboarding asked for them is asked here.
/// Needs a [CreateCircleCubit] of the approved flow above it.
class ApprovedCircleBasicsScreen extends StatefulWidget {
  const ApprovedCircleBasicsScreen({super.key});

  @override
  State<ApprovedCircleBasicsScreen> createState() =>
      _ApprovedCircleBasicsScreenState();
}

class _ApprovedCircleBasicsScreenState
    extends State<ApprovedCircleBasicsScreen> {
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

  Future<void> _create(BuildContext context, CreateCircleCubit cubit) async {
    final NamePreset preset = cubit.state.namePreset;
    final bool ok = cubit.continueFromApprovedBasics(
      presetName: context.tr('circles.preset.${preset.name}'),
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
              if (state.alreadyHasCircle) return const AlreadyHasCircleView();
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
                            title: context.tr('circles.approved_title'),
                            onBack: context.canPop()
                                ? () => context.pop()
                                : () => context.go(Routes.notifications),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AccountNameField(
                            state: state,
                            onRetry: cubit.loadAccount,
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
                          if (state.asksBasics &&
                              state.accountLoad !=
                                  AccountLoad.loading) ...<Widget>[
                            const SizedBox(height: AppSpacing.lg),
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
