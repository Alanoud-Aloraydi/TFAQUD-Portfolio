import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

class SimplifiedSectionTitle extends StatelessWidget {
  const SimplifiedSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: SimplifiedStyle.head(SimplifiedStyle.body));
}
