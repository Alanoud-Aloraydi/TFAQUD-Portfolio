import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The glass bar at the top of the visit page: «رجوع» and the title.
class VisitTitleBar extends StatelessWidget {
  const VisitTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(AppRadius.capsule),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            TextButton.icon(
              onPressed: context.pop,
              icon: const Icon(CupertinoIcons.arrow_right),
              label: Text(context.tr('common.back')),
            ),
            Expanded(
              child: Text(
                context.tr('appointments.visit_title'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 88),
          ],
        ),
      ),
    );
  }
}
