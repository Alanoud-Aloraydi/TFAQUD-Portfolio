import 'package:app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class RequestReplyRow extends StatelessWidget {
  const RequestReplyRow({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: context.tokens.textSecondary),
          ),
        ),
        child,
      ],
    );
  }
}
