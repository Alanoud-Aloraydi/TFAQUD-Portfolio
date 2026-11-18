import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/presentation/widgets/normal_range_band_cell.dart';
import 'package:flutter/material.dart';

/// The four levels side by side, lowest at the start, each with its name
/// and values; the one of [level] framed and bold.
class NormalRangeScale extends StatelessWidget {
  const NormalRangeScale({super.key, required this.range, this.level});

  final NormalRange range;
  final MeasurementLevel? level;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final NormalBand band in range.bands) ...[
              if (band != range.bands.first)
                const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: NormalRangeBandCell(
                  band: band,
                  kind: range.kind,
                  marked: band.level == level,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
