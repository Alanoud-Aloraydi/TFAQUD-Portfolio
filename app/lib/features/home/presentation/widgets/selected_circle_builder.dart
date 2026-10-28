import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectedCircleBuilder extends StatelessWidget {
  const SelectedCircleBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, CareCircleSummary circle) builder;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeCubit, HomeState, CareCircleSummary?>(
      selector: (state) => state.data?.circles
          .where((circle) => circle.id == state.selectedCircleId)
          .firstOrNull,
      builder: (context, circle) {
        if (circle == null) return const SizedBox.shrink();
        return KeyedSubtree(
          key: ValueKey(circle.id),
          child: builder(context, circle),
        );
      },
    );
  }
}
