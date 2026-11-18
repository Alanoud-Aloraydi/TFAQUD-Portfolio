import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/presentation/widgets/normal_range_caption.dart';
import 'package:flutter/material.dart';

/// Which range [range] is (meal state and the patient's condition), under
/// its values.
class NormalRangeCaptionLine extends StatelessWidget {
  const NormalRangeCaptionLine({super.key, required this.range});

  final NormalRange range;

  @override
  Widget build(BuildContext context) => Text(
    normalRangeCaption(context, range.kind, range.profile, range.state),
    style: Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: context.tokens.textSecondary),
  );
}
