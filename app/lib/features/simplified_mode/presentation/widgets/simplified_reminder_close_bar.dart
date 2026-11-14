import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// «إغلاق» at the top: back to where the reminder opened over, answering
/// nothing, so the task stays as it was.
class SimplifiedReminderCloseBar extends StatelessWidget {
  const SimplifiedReminderCloseBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 12, top: 4),
        child: TextButton.icon(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(Routes.simplifiedMode),
          icon: const Icon(AppIcons.x, size: 26),
          label: Text(
            context.tr('simplified_mode.close'),
            style: SimplifiedStyle.label(
              SimplifiedStyle.body,
              color: SimplifiedStyle.surface,
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: SimplifiedStyle.surface,
            minimumSize: const Size(0, SimplifiedStyle.touch),
          ),
        ),
      ),
    );
  }
}
