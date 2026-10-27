import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/widgets/pill_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shown instead of the form when the account already has a circle for its own
/// care: the person learns it at once, before filling anything in.
class AlreadyHasCircleView extends StatelessWidget {
  const AlreadyHasCircleView({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      children: <Widget>[
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.check_circle_outline,
                size: 56,
                color: AppColors.brand,
              ),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(
                  context.tr('circles.already_title'),
                  textAlign: TextAlign.center,
                  style: text.headlineSmall,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('circles.already_has_circle'),
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: AppColors.ink2),
              ),
            ],
          ),
        ),
        PillButton(
          label: context.tr('circles.back_home'),
          onPressed: () => context.go(Routes.today),
        ),
      ],
    );
  }
}
