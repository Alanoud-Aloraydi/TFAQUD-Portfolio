import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/widgets/already_has_circle_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
