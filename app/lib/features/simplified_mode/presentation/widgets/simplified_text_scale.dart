import 'package:app/features/simplified_mode/presentation/cubit/simplified_settings_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
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
    return _scaled(context, factor, child);
  }
}

/// A page or part the simplified mode takes from the detailed mode (the
/// medical file's edit page, the contact form) at the simplified mode's
/// size: the detailed body text grows to [SimplifiedStyle.body], and the rest
/// of its type in proportion, on top of [SimplifiedTextScale].
class SimplifiedDetailScale extends StatelessWidget {
  const SimplifiedDetailScale({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double detailedBody =
        Theme.of(context).textTheme.bodyLarge?.fontSize ?? SimplifiedStyle.body;
    return _scaled(context, SimplifiedStyle.body / detailedBody, child);
  }
}

Widget _scaled(BuildContext context, double factor, Widget child) {
  final MediaQueryData data = MediaQuery.of(context);
  return MediaQuery(
    data: data.copyWith(textScaler: ScaledOverPhone(data.textScaler, factor)),
    child: child,
  );
}

/// The phone's own text size ([phone]) applied to text [factor] times
/// larger. Android 14+ grows large text less than small text at its big
/// sizes (a non-linear scaler); flattening it to one linear factor read at
/// size 1 would grow headings by the full factor and overflow them, so the
/// phone's curve is kept.
@visibleForTesting
class ScaledOverPhone extends TextScaler {
  const ScaledOverPhone(this.phone, this.factor);

  final TextScaler phone;
  final double factor;

  @override
  double scale(double fontSize) => phone.scale(fontSize * factor);

  @Deprecated('Use scale instead.')
  @override
  double get textScaleFactor => scale(1);

  @override
  bool operator ==(Object other) =>
      other is ScaledOverPhone &&
      other.phone == phone &&
      other.factor == factor;

  @override
  int get hashCode => Object.hash(phone, factor);
}
