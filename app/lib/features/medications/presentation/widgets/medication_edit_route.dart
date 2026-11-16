import 'package:app/core/navigation/routers.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Opens the medicine's form and, when it saved, closes the medicine's page
/// with it, so the list behind both is reloaded once.
Future<void> editMedication(
  BuildContext context,
  String circleId,
  String planId,
) async {
  final changed = await context.push<bool>(
    Routes.editMedication(circleId, planId),
  );
  if (changed == true && context.mounted) {
    context.pop(true);
  }
}
