import 'package:app/app/router/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/presentation/widgets/request_sent_details_card.dart';
import 'package:app/features/circles/presentation/widgets/request_sent_header.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The waiting state after a request is sent (CREAT-05): the circle does not
/// exist yet, and the page says who has to answer. The button goes back to
/// the home page.
class RequestSentView extends StatelessWidget {
  const RequestSentView({super.key, required this.request});

  /// The gap above the round mark, which stands in for a page heading.
  static const double topGap = 48;

  final SentCircleRequest request;

  @override
  Widget build(BuildContext context) {
    final bool accepted = request.status == CircleRequestStatus.accepted;
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(height: topGap),
                RequestSentHeader(accepted: accepted),
                const SizedBox(height: AppSpacing.xl),
                RequestSentDetailsCard(request: request, accepted: accepted),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go(Routes.today),
            style: OutlinedButton.styleFrom(
              shape: const StadiumBorder(),
              minimumSize: const Size.fromHeight(AppSizes.button),
              foregroundColor: AppSemanticColors.textPrimary,
              side: const BorderSide(
                color: AppSemanticColors.borderControlBase,
              ),
            ),
            child: Text(context.tr('circles.request_back')),
          ),
        ),
      ],
    );
  }
}

/// The avatar with the sender's first letter, their name and a short line
/// saying what they asked, at the top of the request card.
Widget requestSenderRow(BuildContext context, String name) {
  final TextTheme text = Theme.of(context).textTheme;
  return Row(
    children: <Widget>[
      Container(
        width: AppSizes.avatarLarge,
        height: AppSizes.avatarLarge,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppSemanticColors.selectedSurface,
          shape: BoxShape.circle,
        ),
        child: Text(
          name.isEmpty ? '؟' : name.characters.first,
          style: text.titleLarge?.copyWith(
            color: AppSemanticColors.textPrimary,
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(header: true, child: Text(name, style: text.titleMedium)),
            Text(
              context.tr('circles.reply_subtitle'),
              style: text.bodyMedium?.copyWith(
                color: context.tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
