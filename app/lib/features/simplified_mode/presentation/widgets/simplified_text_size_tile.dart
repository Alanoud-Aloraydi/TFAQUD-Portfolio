import 'package:app/features/simplified_mode/domain/entities/simplified_reading.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_settings_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/apply_text_scale.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One text size to pick, showing «أ» at the size it gives.
class SimplifiedTextSizeTile extends StatelessWidget {
  const SimplifiedTextSizeTile({
    super.key,
    required this.size,
    required this.selected,
  });

  static const Map<SimplifiedTextSize, double> _sample =
      <SimplifiedTextSize, double>{
        SimplifiedTextSize.normal: 24,
        SimplifiedTextSize.large: 34,
        SimplifiedTextSize.larger: 44,
      };

  final SimplifiedTextSize size;

  /// Whether this is the size chosen now.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () => context.read<SimplifiedSettingsCubit>().setTextSize(size),
        child: Container(
          height: 104,
          decoration: simplifiedTextSizeTileDecoration(selected: selected),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // A fixed size, so each tile shows its own
              // size and not the one chosen now.
              MediaQuery.withNoTextScaling(
                child: Text(
                  context.tr('simplified_mode.size_sample'),
                  style: SimplifiedStyle.head(_sample[size]!, height: 1),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('simplified_mode.size.${size.name}'),
                style: SimplifiedStyle.head(SimplifiedStyle.caption),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

/// The box of a text-size tile: tinted with a thick ink edge when chosen,
/// plain with a thin grey edge otherwise.
BoxDecoration simplifiedTextSizeTileDecoration({required bool selected}) {
  return BoxDecoration(
    color: selected ? SimplifiedColors.accentTint : SimplifiedColors.surface,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(
      color: selected ? SimplifiedColors.ink : SimplifiedColors.disabled,
      width: selected ? 3 : 2,
    ),
  );
}
