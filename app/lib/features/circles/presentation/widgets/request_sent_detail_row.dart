import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/presentation/widgets/request_sent_details_card.dart';
import 'package:flutter/material.dart';

/// One row of [RequestSentDetailsCard]: its label and its value.
class RequestSentDetailRow extends StatelessWidget {
  const RequestSentDetailRow({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(
                color: context.tokens.textSecondary,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
