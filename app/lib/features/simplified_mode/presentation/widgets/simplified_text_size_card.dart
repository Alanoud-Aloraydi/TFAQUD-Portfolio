import 'package:app/features/simplified_mode/domain/entities/simplified_text_size.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_settings_cubit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Three big tiles, each showing «أ» at the size it gives.
class SimplifiedTextSizeCard extends StatelessWidget {
  const SimplifiedTextSizeCard({super.key});

  static const Map<SimplifiedTextSize, double> _sample =
      <SimplifiedTextSize, double>{
        SimplifiedTextSize.normal: 24,
        SimplifiedTextSize.large: 34,
        SimplifiedTextSize.larger: 44,
      };

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
                  child: Semantics(
                    button: true,
                    selected: size == selected,
                    child: GestureDetector(
                      onTap: () => context
                          .read<SimplifiedSettingsCubit>()
                          .setTextSize(size),
                      child: Container(
                        height: 104,
                        decoration: BoxDecoration(
                          color: size == selected
                              ? SimplifiedStyle.accentTint
                              : SimplifiedStyle.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: size == selected
                                ? SimplifiedStyle.ink
                                : SimplifiedStyle.disabled,
                            width: size == selected ? 3 : 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            // A fixed size, so each tile shows its own
                            // size and not the one chosen now.
                            MediaQuery.withNoTextScaling(
                              child: Text(
                                context.tr('simplified_mode.size_sample'),
                                style: SimplifiedStyle.head(
                                  _sample[size]!,
                                  height: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr('simplified_mode.size.${size.name}'),
                              style: SimplifiedStyle.head(
                                SimplifiedStyle.caption,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
