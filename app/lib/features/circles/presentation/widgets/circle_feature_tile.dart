import 'package:app/app/router/routers.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/features/circles/presentation/cubit/circle_member_actions.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/widgets/circle_feature_tile_content.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A tile under the patient card: an outline icon, its name and one line
/// on what it holds. Both tiles take the height of the taller one.
class CircleFeatureTile extends StatelessWidget {
  const CircleFeatureTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.attention = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Something here waits to be filled: a honey tile with the yellow «!».
  final bool attention;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: spoken('$title، $subtitle'),
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: attention
            ? AppSemanticColors.surfaceAttention
            : AppSemanticColors.surfaceContent,
        // Only a file that needs attention keeps a line, in its colour.
        shape: AppRadius.shape(
          AppRadius.m,
          side: attention
              ? const BorderSide(color: AppSemanticColors.borderAttention)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: CircleFeatureTileContent(
              icon: icon,
              iconColor: iconColor,
              title: title,
              subtitle: subtitle,
              attention: attention,
            ),
          ),
        ),
      ),
    );
  }
}

/// Creates the circle of the page's flow ([CreateCircleCubit.create], with
/// the chip text [presetName]). When it is created, the «الدائرة» tab opens
/// on it (the home screen selects the new circle), where the medical file
/// waits with its «!» until it is filled, and a short line says the circle
/// is ready. `go` replaces the whole stack, so back never returns to the
/// creation pages. A refusal or a missing answer stays on the page, which
/// shows it.
///
/// [CircleFlow.approved] may instead commit the account to simplified mode
/// right there; the person goes straight to the simplified home, with no
/// detailed circle to visit and no sign-out/in needed to see it.
Future<void> createCircleAndOpen(
  BuildContext context,
  CreateCircleCubit cubit, {
  String presetName = '',
}) async {
  // Read before the page leaves the screen.
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final String notice = context.tr('circles.created_notice');
  final bool created = await cubit.create(presetName: presetName);
  if (!created || !context.mounted) return;
  if (cubit.state.switchToSimplified) {
    context.go(Routes.simplifiedMode);
    return;
  }
  context.go(Routes.circle);
  AppToast.showText(messenger, notice);
}
