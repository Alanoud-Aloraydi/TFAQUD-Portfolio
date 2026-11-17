import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/widgets/account_load_failed.dart';
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

class _SelfCircleBasicsScreenState extends State<SelfCircleBasicsScreen>
    with CreateCircleNameState<SelfCircleBasicsScreen> {
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
                  title: context.tr('circles.self_title'),
                  subtitle: context.tr('circles.self_subtitle'),
                  onBack: context.canPop() ? () => context.pop() : null,
                ),
                const SizedBox(height: AppSpacing.xl),
                CircleNameChips(
                  cubit: cubit,
                  state: state,
                  customName: customName,
                ),
                // The one line under the title says who sees the name;
                // nothing more here.
                if (state.accountLoad == AccountLoad.failed) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  AccountLoadFailed(onRetry: cubit.loadAccount),
                ],
                CircleBasicsFields(
                  cubit: cubit,
                  state: state,
                  topGap: AppSpacing.xl,
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
