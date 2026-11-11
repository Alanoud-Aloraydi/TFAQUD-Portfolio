import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/presentation/widgets/inbox_cards.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The requests that were already answered, kept apart from the ones that
/// still wait for a reply.
class PreviousRequestsSection extends StatelessWidget {
  const PreviousRequestsSection({super.key, required this.requests});

  final List<SentCircleRequest> requests;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.inset,
            top: AppSpacing.lg,
            bottom: AppSpacing.labelGap,
          ),
          child: Semantics(
            header: true,
            child: Text(
              context.tr('circles.previous_title'),
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: context.tokens.textSecondary),
            ),
          ),
        ),
        for (final SentCircleRequest request in requests)
          DeclinedRequestCard(request: request),
      ],
    );
  }
}
