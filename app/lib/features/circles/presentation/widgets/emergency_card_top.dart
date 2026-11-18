import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/presentation/widgets/emergency_badge.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';
import 'package:flutter/material.dart';

/// The red badge at the top of the card and «للقراءة فقط» beside it.
class EmergencyCardTop extends StatelessWidget {
  const EmergencyCardTop({super.key, required this.words});

  final EmergencyCardText words;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Row(
      children: <Widget>[
        EmergencyBadge(label: words.t('title')),
        const Spacer(),
        Icon(
          NoticeIcons.lock,
          size: AppSizes.iconSmall,
          color: context.tokens.textSecondary,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          words.t('read_only'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}
