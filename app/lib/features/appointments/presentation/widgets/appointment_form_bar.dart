import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The glass bar over the appointment form: «إلغاء», the title, «حفظ».
class AppointmentFormBar extends StatelessWidget {
  const AppointmentFormBar({
    super.key,
    required this.editing,
    required this.onSave,
  });

  final bool editing;

  /// Null while the form is being saved.
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(AppRadius.capsule),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(context.tr('common.cancel')),
            ),
            Expanded(
              child: Text(
                context.tr(editing ? 'appointments.edit' : 'appointments.new'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
              child: FilledButton(
                onPressed: onSave,
                child: Text(context.tr('appointments.save')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
