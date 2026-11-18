import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:app/features/simplified_mode/presentation/widgets/measurement_verdict.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

/// What the saved reading means, in a word beside its mark.
class SimplifiedDoneVerdictRow extends StatelessWidget {
  const SimplifiedDoneVerdictRow({super.key, required this.verdict});

  final MeasurementVerdict verdict;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ExcludeSemantics(child: Icon(verdict.level.icon, size: 28)),
          const SizedBox(width: 8),
          Text(
            verdict.label,
            style: SimplifiedStyle.head(SimplifiedStyle.headline),
          ),
        ],
      ),
    );
  }
}
