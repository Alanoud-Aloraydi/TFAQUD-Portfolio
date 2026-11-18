import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The form page while the visit to edit is not in the list: loading, a
/// retry when the list failed, or that the visit is gone.
class AppointmentFormMissing extends StatelessWidget {
  const AppointmentFormMissing({
    super.key,
    required this.state,
    required this.circleId,
  });

  final AppointmentsState state;
  final String circleId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: switch (state.status) {
          AppointmentsLoadStatus.initial ||
          AppointmentsLoadStatus.loading => const LoadingNote(),
          AppointmentsLoadStatus.failure => TextButton(
            onPressed: () => context.read<AppointmentsCubit>().load(circleId),
            child: Text(context.tr(state.errorKey ?? 'error.unknown')),
          ),
          AppointmentsLoadStatus.ready => Text(
            context.tr('error.resource_not_found'),
          ),
        },
      ),
    );
  }
}
