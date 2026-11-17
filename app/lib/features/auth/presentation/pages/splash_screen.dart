import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/launch_curtain.dart';
import 'package:app/core/widgets/loading/pulsing_logo.dart';
import 'package:app/features/auth/presentation/cubit/splash_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The first page. It shows the breathing logo while the app finds out
/// whether this phone is signed in, then moves on, under the
/// [LaunchCurtain], which it tells when it knows. It needs a [SplashCubit]
/// above it in the widget tree.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SplashCubit, StartDestination>(
      listener: (context, destination) {
        if (destination != StartDestination.checking) {
          LaunchCurtain.ready.value = true;
        }
        switch (destination) {
          case StartDestination.home:
            context.go(Routes.today);
          case StartDestination.simplifiedHome:
            context.go(Routes.simplifiedMode);
          case StartDestination.signIn:
            context.go(Routes.auth);
          case StartDestination.onboarding:
            context.go(Routes.onboarding);
          case StartDestination.checking:
          case StartDestination.unavailable:
            break;
        }
      },
      builder: (context, destination) => Scaffold(
        // White, as the launch screen before it and the design's page.
        backgroundColor: AppSemanticColors.surfaceContent,
        body: destination == StartDestination.unavailable
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.inset,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        context.tr('auth.session_check_failed'),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.inset),
                      FilledButton(
                        onPressed: context.read<SplashCubit>().decide,
                        child: Text(context.tr('auth.retry')),
                      ),
                    ],
                  ),
                ),
              )
            : const Center(child: PulsingLogo(size: AppSizes.loadingPage)),
      ),
    );
  }
}
