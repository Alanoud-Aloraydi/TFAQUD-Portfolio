import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/inline_error.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:flutter/material.dart';

/// Why the last try to create the circle was refused, under what the page
/// asks; nothing while there is no message.
class CircleBasicsError extends StatelessWidget {
  const CircleBasicsError({super.key, required this.state});

  final CreateCircleState state;

  @override
  Widget build(BuildContext context) {
    final String? messageKey = state.errorKey;
    if (messageKey == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: InlineError(messageKey: messageKey),
    );
  }
}
