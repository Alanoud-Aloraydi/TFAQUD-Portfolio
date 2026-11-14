import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SimplifiedEmptyCard extends StatelessWidget {
  const SimplifiedEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SimplifiedCard(
      child: Text(
        context.tr('simplified_mode.nothing_today'),
        textAlign: TextAlign.center,
        style: SimplifiedStyle.head(SimplifiedStyle.headline),
      ),
    );
  }
}
