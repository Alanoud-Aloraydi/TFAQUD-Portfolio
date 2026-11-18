import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/features/appointments/domain/appointment_group.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_state.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What a list of appointments shows below its header: the loading note,
/// the retry view, [empty] when there is nothing, else an appointment card
/// for each booking in [values].
List<Widget> appointmentListBody(
  BuildContext context, {
  required AppointmentsState state,
  required List<AppointmentGroup> values,
  required String circleId,
  required Widget empty,
  required bool canManage,
  bool showRelativeDate = false,
  bool editable = true,
}) {
  return <Widget>[
    if (state.status == AppointmentsLoadStatus.loading && values.isEmpty)
      const LoadingNote()
    else if (state.status == AppointmentsLoadStatus.failure)
      RetryView(
        messageKey: state.errorKey ?? 'error.unknown',
        onRetry: () => context.read<AppointmentsCubit>().load(circleId),
      )
    else if (values.isEmpty)
      empty
    else
      for (final AppointmentGroup group in values) ...<Widget>[
        AppointmentCard(
          value: group.shown,
          circleId: circleId,
          canManage: canManage,
          showRelativeDate: showRelativeDate,
          editable: editable,
          others: group.others,
          all: state.appointments,
        ),
        const SizedBox(height: AppItemCard.listGap),
      ],
  ];
}
