import 'package:app/features/simplified_mode/presentation/cubit/simplified_settings_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/apply_text_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Applies the text size chosen in «حسابي» to every simplified screen, on
/// top of the phone's own text size, and at once when it changes.
class SimplifiedTextScale extends StatelessWidget {
  const SimplifiedTextScale({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double factor = context.select<SimplifiedSettingsCubit, double>(
      (cubit) => cubit.state.textSize.factor,
    );
    return applyTextScale(context, factor, child);
  }
}
