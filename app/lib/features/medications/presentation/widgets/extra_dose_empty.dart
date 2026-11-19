import 'dart:async';

import 'package:app/core/navigation/care_item_routes.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// «سجّل جرعة الآن» with no medicine taken today: the way to add one.
class ExtraDoseEmpty extends StatelessWidget {
  const ExtraDoseEmpty({super.key, required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context) => EmptyStateNote(
    context.tr('medications.dose_now_empty'),
    actionLabel: context.tr('add.medication'),
    onAction: () {
      final GoRouter router = GoRouter.of(context);
      Navigator.of(context).pop(false);
      unawaited(router.push<bool>(CareItemRoutes.newMedication(circleId)));
    },
  );
}
