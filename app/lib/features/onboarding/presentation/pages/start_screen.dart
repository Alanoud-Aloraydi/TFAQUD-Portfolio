import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:app/features/onboarding/presentation/widgets/start_actions.dart';
import 'package:app/features/onboarding/presentation/widgets/start_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Step 2 of 2 of the first account set-up («كيف تحب تستخدم تفقُد؟»), and
/// the page the "+" next to the circles opens to add another circle
/// ([addingCircle]: no steps, no «تخطي الآن», no invitations).
///
/// In the first set-up, the person's own pending invitations show above the
/// choice ([PendingInvitesSection]): someone may have invited them before
/// they opened the app. Accepting one leaves for «اليوم» with that circle,
/// with no need to choose below. [InboxCubit] and [PendingInvitesSection]
/// stay in the circles feature on purpose: invitations are circle logic,
/// shared with the notifications page and the home bell.
///
/// The choice is kept in [OnboardingCubit] and decides the next page:
/// «أتابع رعايتي بنفسي» opens the page that creates the person's own circle;
/// «أتابع رعاية شخص آخر» then asks whether that person uses the app — if so,
/// the next page sends them a request by phone number, otherwise it creates
/// the circle directly.
class StartScreen extends StatelessWidget {
  const StartScreen({super.key, this.addingCircle = false});

  /// True when opened from the "+" to add another circle.
  final bool addingCircle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: BlocBuilder<OnboardingCubit, OnboardingState>(
            builder: (BuildContext context, OnboardingState state) {
              return Column(
                children: <Widget>[
                  Expanded(
                    child: StartContent(
                      state: state,
                      addingCircle: addingCircle,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  StartActions(state: state, addingCircle: addingCircle),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
