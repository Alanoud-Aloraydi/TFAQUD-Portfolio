import 'package:app/features/home/presentation/cubit/home_state.dart';
import 'package:flutter/material.dart';

/// Circle choices share one selection across all home tabs.
class HomeWidget extends StatelessWidget {
  const HomeWidget({super.key, required this.state, required this.onSelected});

  final HomeState state;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final circle in state.data?.circles ?? [])
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(circle.name),
                selected: circle.id == state.selectedCircleId,
                onSelected: (_) => onSelected(circle.id),
              ),
            ),
        ],
      ),
    );
  }
}
