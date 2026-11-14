import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

class SimplifiedMedicalFileRow extends StatelessWidget {
  const SimplifiedMedicalFileRow({
    super.key,
    required this.label,
    required this.value,
    required this.last,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: SimplifiedStyle.gap),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(
                  bottom: BorderSide(color: SimplifiedStyle.disabled),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: SimplifiedStyle.text(
                SimplifiedStyle.body,
                weight: AppTextTheme.medium,
              ),
            ),
            const SizedBox(height: 4),
            Text(value, style: SimplifiedStyle.head(SimplifiedStyle.title)),
          ],
        ),
      ),
    );
  }
}
