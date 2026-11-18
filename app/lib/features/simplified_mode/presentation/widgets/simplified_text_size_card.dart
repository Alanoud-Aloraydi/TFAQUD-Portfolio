import 'package:app/features/simplified_mode/domain/entities/simplified_text_size.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_settings_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_text_size_tile.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Three big tiles, each showing «أ» at the size it gives.
class SimplifiedTextSizeCard extends StatelessWidget {
  const SimplifiedTextSizeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final SimplifiedTextSize selected = context
        .select<SimplifiedSettingsCubit, SimplifiedTextSize>(
          (cubit) => cubit.state.textSize,
        );
    return SimplifiedCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SimplifiedStyle.pad,
        vertical: SimplifiedStyle.gap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.tr('simplified_mode.text_size'),
            style: SimplifiedStyle.head(SimplifiedStyle.body),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              for (final SimplifiedTextSize size
                  in SimplifiedTextSize.values) ...<Widget>[
                if (size != SimplifiedTextSize.normal)
                  const SizedBox(width: 10),
                Expanded(
                  child: SimplifiedTextSizeTile(
                    size: size,
                    selected: size == selected,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
