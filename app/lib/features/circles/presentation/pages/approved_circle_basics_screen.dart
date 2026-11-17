import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/widgets/account_name_field.dart';
import 'package:app/features/circles/presentation/widgets/already_has_circle_view.dart';
import 'package:app/features/circles/presentation/widgets/circle_basics_error.dart';
import 'package:app/features/circles/presentation/widgets/circle_basics_fields.dart';
import 'package:app/features/circles/presentation/widgets/circle_basics_frame.dart';
import 'package:app/features/circles/presentation/widgets/circle_name_chips.dart';
import 'package:app/features/circles/presentation/widgets/create_circle_name_state.dart';
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
  State<ApprovedCircleBasicsScreen> createState() => _ApprovedBasicsState();
}

class _ApprovedBasicsState extends State<ApprovedCircleBasicsScreen>
    with CreateCircleNameState<ApprovedCircleBasicsScreen> {
  @override
  Widget build(BuildContext context) {
    final CreateCircleCubit cubit = context.read<CreateCircleCubit>();
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<CreateCircleCubit, CreateCircleState>(
          builder: (BuildContext context, CreateCircleState state) {
            if (state.alreadyHasCircle) return const AlreadyHasCircleView();
            return CircleBasicsFrame(
              state: state,
              onCreate: () => create(cubit),
              children: <Widget>[
                StepHeader(
                  title: context.tr('circles.approved_title'),
                  onBack: context.canPop()
                      ? () => context.pop()
                      : () => context.go(Routes.notifications),
                ),
                const SizedBox(height: AppSpacing.xl),
                AccountNameField(state: state, onRetry: cubit.loadAccount),
                const SizedBox(height: AppSpacing.xl),
                CircleNameChips(
                  cubit: cubit,
                  state: state,
                  customName: customName,
                ),
                const SizedBox(height: AppSpacing.sm),
                InsetText.note(context.tr('circles.name_hint')),
                CircleBasicsFields(
                  cubit: cubit,
                  state: state,
                  topGap: AppSpacing.lg,
                ),
                CircleBasicsError(state: state),
              ],
            );
          },
        ),
      ),
    );
  }
}
