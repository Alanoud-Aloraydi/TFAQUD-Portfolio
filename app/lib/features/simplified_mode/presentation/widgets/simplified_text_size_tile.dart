import 'package:app/features/simplified_mode/domain/entities/simplified_text_size.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_settings_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_text_size_tile_decoration.dart';
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
