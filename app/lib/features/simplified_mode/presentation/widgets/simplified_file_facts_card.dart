import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_file_rows.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_medical_file_row.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

/// The patient's answers, one big row under the other in a single card.
class SimplifiedFileFactsCard extends StatelessWidget {
  const SimplifiedFileFactsCard({super.key, required this.file});

  final MedicalFile file;

  @override
  Widget build(BuildContext context) {
    final List<(String, String)> rows = simplifiedFileRows(context, file);
    return SimplifiedCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SimplifiedStyle.pad,
        vertical: 4,
      ),
      child: Column(
        children: <Widget>[
          for (int index = 0; index < rows.length; index++)
            SimplifiedMedicalFileRow(
              label: rows[index].$1,
              value: rows[index].$2,
              last: index == rows.length - 1,
            ),
        ],
      ),
    );
  }
}
