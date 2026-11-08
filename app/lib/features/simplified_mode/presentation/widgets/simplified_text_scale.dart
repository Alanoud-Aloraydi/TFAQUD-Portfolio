import 'package:app/features/simplified_mode/presentation/cubit/simplified_settings_cubit.dart';
import 'package:flutter/widgets.dart';
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
    final MediaQueryData data = MediaQuery.of(context);
    return MediaQuery(
      data: data.copyWith(
        textScaler: TextScaler.linear(data.textScaler.scale(1) * factor),
      ),
      child: child,
    );
  }
}
