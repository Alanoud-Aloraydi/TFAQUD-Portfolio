import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/feedback/inline_error.dart';
import 'package:app/features/circles/presentation/circle_creation_finish.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/widgets/account_name_field.dart';
import 'package:app/features/circles/presentation/widgets/already_has_circle_view.dart';
import 'package:app/features/circles/presentation/widgets/birth_date_city_fields.dart';
import 'package:app/features/circles/presentation/widgets/circle_step_header.dart';
import 'package:app/features/circles/presentation/widgets/read_only_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The page after the patient agreed to a request (PROFILE-01C): the name
/// comes from the account and the circle name was set by the sender, so the
/// patient only creates the circle. The birth date and city come from the
/// account; an account made before onboarding asked for them is asked here.
/// Needs a [CreateCircleCubit] of the approved flow above it.
class ApprovedCircleBasicsScreen extends StatelessWidget {
  const ApprovedCircleBasicsScreen({super.key});

  Future<void> _create(BuildContext context, CreateCircleCubit cubit) async {
    if (cubit.continueFromApprovedBasics()) {
      await createCircleAndOpen(context, cubit);
    }
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
              return Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
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
                          const SizedBox(height: AppSpacing.lg),
                          ReadOnlyField(
                            label: context.tr('circles.approved_circle_name'),
                            note: context.tr('circles.set_by_requester'),
                            child: Text(
                              state.circleName,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
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
