import 'dart:async';

import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Future<void> showHomeAddSheet(
  BuildContext context, {
  required String circleId,
  required VoidCallback onMedicationSaved,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => _HomeAddSheet(
      onMedication: () {
        Navigator.of(sheetContext).pop();
        unawaited(
          context.push<bool>(Routes.newMedication(circleId)).then((saved) {
            if (saved == true) onMedicationSaved();
          }),
        );
      },
    ),
  );
}

class _HomeAddSheet extends StatelessWidget {
  const _HomeAddSheet({required this.onMedication});

  final VoidCallback onMedication;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('add.title'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            _AddOption(
              icon: Icons.medication_outlined,
              title: context.tr('add.medication'),
              hint: context.tr('add.medication_hint'),
              onTap: onMedication,
            ),
            _AddOption(
              icon: Icons.water_drop_outlined,
              title: context.tr('add.measurement'),
              hint: context.tr('add.measurement_hint'),
            ),
            _AddOption(
              icon: Icons.event_outlined,
              title: context.tr('add.appointment'),
              hint: context.tr('add.appointment_hint'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddOption extends StatelessWidget {
  const _AddOption({
    required this.icon,
    required this.title,
    required this.hint,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        enabled: onTap != null,
        onTap: onTap,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(hint),
        trailing: onTap == null ? null : const Icon(Icons.chevron_left),
      ),
    );
  }
}
