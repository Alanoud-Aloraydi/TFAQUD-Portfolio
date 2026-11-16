import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/features/circles/presentation/widgets/inbox_card_text.dart';
import 'package:flutter/material.dart';

/// The white card every item of the notifications page sits in.
class InboxCard extends StatelessWidget {
  const InboxCard({
    super.key,
    required this.avatar,
    required this.title,
    required this.body,
    this.pill,
    this.actions,
  });

  final Widget avatar;
  final String title;
  final String body;
  final Widget? pill;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppSurfaces.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              avatar,
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: InboxCardText(title: title, body: body),
              ),
              if (pill != null) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                pill!,
              ],
            ],
          ),
          if (actions != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            actions!,
          ],
        ],
      ),
    );
  }
}
