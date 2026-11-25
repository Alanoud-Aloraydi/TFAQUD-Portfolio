import 'package:app/app/router/routers.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The page both circle-naming flows open on: what the page asks for the
/// state of the [CreateCircleCubit] above it, or, when the person already
/// has a circle of their own, the note that says so in its place.
class CircleBasicsScaffold extends StatelessWidget {
  const CircleBasicsScaffold({
    super.key,
    required this.onCreate,
    required this.children,
  });

  final VoidCallback onCreate;

  /// What the page asks, top to bottom, for the state on show.
  final List<Widget> Function(BuildContext context, CreateCircleState state)
  children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<CreateCircleCubit, CreateCircleState>(
          builder: (BuildContext context, CreateCircleState state) {
            if (state.alreadyHasCircle) return const AlreadyHasCircleView();
            return CircleBasicsFrame(
              state: state,
              onCreate: onCreate,
              children: children(context, state),
            );
          },
        ),
      ),
    );
  }
}

/// The shape both circle-naming pages have: what they ask, scrolling, over
/// «إنشاء» at the bottom.
class CircleBasicsFrame extends StatelessWidget {
  const CircleBasicsFrame({
    super.key,
    required this.state,
    required this.onCreate,
    required this.children,
  });

  final CreateCircleState state;
  final VoidCallback onCreate;

  /// What this page asks, top to bottom.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PillButton(
            label: context.tr('circles.create'),
            isLoading: state.busy,
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}

/// Shown instead of the form when the account already has a circle for its own
/// care: the person learns it at once, before filling anything in.
class AlreadyHasCircleView extends StatelessWidget {
  const AlreadyHasCircleView({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      children: <Widget>[
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                ActionIcons.checkCircle,
                size: AppSizes.iconHero,
                color: AppSemanticColors.textPrimary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                header: true,
                child: Text(
                  context.tr('circles.already_title'),
                  textAlign: TextAlign.center,
                  style: text.headlineSmall,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.tr('circles.already_has_circle'),
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(
                  color: context.tokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
        PillButton(
          label: context.tr('circles.back_home'),
          onPressed: () => context.go(Routes.today),
        ),
      ],
    );
  }
}
