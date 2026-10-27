import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectedCircleBuilder extends StatelessWidget {
  const SelectedCircleBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, String circleId) builder;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeCubit, HomeState, String?>(
      selector: (state) => state.selectedCircleId,
      builder: (context, circleId) {
        if (circleId == null) return const SizedBox.shrink();
        return KeyedSubtree(
          key: ValueKey(circleId),
          child: builder(context, circleId),
        );
      },
    );
  }
}
