import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

/// What to take of a dose, on one line: «حبة واحدة», and the strength
/// beside it when [strength] asks for it.
class SimplifiedDoseLine extends StatelessWidget {
  const SimplifiedDoseLine({
    super.key,
    required this.dose,
    required this.strength,
  });

  final DoseOccurrence dose;

  /// False when the medicine's reason is shown as a chip under this line
  /// («الكوليسترول»): the reason tells the medicines apart, so the
  /// strength is not repeated.
  final bool strength;

  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.end,
    spacing: 10,
    children: <Widget>[
      Text(
        simplifiedDoseAmount(context, dose),
        style: SimplifiedStyle.head(SimplifiedStyle.headline),
      ),
      if (strength)
        Text(
          simplifiedStrength(context, dose),
          style: SimplifiedStyle.text(
            SimplifiedStyle.body,
            weight: AppTextTheme.medium,
          ),
        ),
    ],
  );
}
