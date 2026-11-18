import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Asks before throwing the recording away, because it cannot come back.
Future<void> removeVisitAudio(BuildContext context) async {
  final remove = await showAppAlert<bool>(
    context,
    title: context.tr('appointments.audio_remove_confirm'),
    actions: [
      AppAlertAction<bool>(label: context.tr('common.cancel'), value: false),
      AppAlertAction<bool>(
        label: context.tr('appointments.audio_remove'),
        value: true,
        destructive: true,
      ),
    ],
  );
  if (remove == true && context.mounted) {
    context.read<VisitCubit>().removeAudio();
  }
}
