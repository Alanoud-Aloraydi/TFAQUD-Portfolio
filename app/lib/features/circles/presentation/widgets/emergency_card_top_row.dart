import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/buttons/back_link.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// «رجوع» and, once the card is on screen, «تصدير».
class EmergencyCardTopRow extends StatelessWidget {
  const EmergencyCardTopRow({
    super.key,
    required this.closeTo,
    required this.canExport,
    required this.onExport,
  });

  /// Where «رجوع» goes when there is no page under the card.
  final String closeTo;
  final bool canExport;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        BackLink(
          onPressed: context.canPop()
              ? () => context.pop()
              : () => context.go(closeTo),
        ),
        const Spacer(),
        if (canExport)
          TextButton.icon(
            onPressed: onExport,
            icon: const Icon(AppIcons.export, size: AppSizes.iconSmall),
            label: Text(context.tr('emergency_card.export')),
          ),
      ],
    );
  }
}
