import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/widgets/already_has_circle_view.dart';
import 'package:app/features/circles/presentation/widgets/circle_basics_frame.dart';
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
