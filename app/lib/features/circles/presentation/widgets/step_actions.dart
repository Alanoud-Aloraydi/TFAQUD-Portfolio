import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/widgets/pill_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The two buttons at the bottom of the optional steps: the main button, wide,
/// and "تخطي", narrow and outlined. While [isLoading] is true the main button
/// shows a spinner and the skip button is off.
class StepActions extends StatelessWidget {
  const StepActions({
    super.key,
    required this.nextLabel,
    required this.onNext,
    required this.onSkip,
    this.isLoading = false,
  });

  final String nextLabel;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 2,
          child: PillButton(
            label: nextLabel,
            onPressed: onNext,
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: isLoading ? null : onSkip,
            style: OutlinedButton.styleFrom(
              shape: const StadiumBorder(),
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppColors.brand,
              side: const BorderSide(color: AppColors.brand),
            ),
            child: Text(context.tr('circles.skip')),
          ),
        ),
      ],
    );
  }
}
