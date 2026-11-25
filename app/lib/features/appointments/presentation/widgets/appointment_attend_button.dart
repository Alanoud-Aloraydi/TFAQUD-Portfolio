import 'dart:async';

import 'package:app/app/router/care_item_routes.dart';
import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/task_button.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/entities/appointment_group.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_loading.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «حضرت»: marks the visit attended, then opens its «ورقة الزيارة» to
/// fill in; «السجل» can change it later. Who may press it, and the two
/// choices beside it, are `appointmentTodayActions`.
class AppointmentAttendButton extends StatelessWidget {
  const AppointmentAttendButton({
    super.key,
    required this.value,
    required this.circleId,
  });

  final CareAppointment value;
  final String circleId;

  @override
  Widget build(BuildContext context) => TaskButton(
    role: TaskButtonRole.answer,
    icon: CupertinoIcons.checkmark,
    label: context.tr('appointments.mark_completed'),
    onPressed: () => _attend(context),
  );

  Future<void> _attend(BuildContext context) async {
    final String? errorKey = await context.read<AppointmentsCubit>().setStatus(
      circleId,
      value,
      AppointmentStatus.completed,
    );
    if (!context.mounted) return;
    if (errorKey != null) {
      return AppToast.show(context, errorKey, kind: ToastKind.error);
    }
    AppToast.show(context, 'toast.appointment_completed');
    final String visit = CareItemRoutes.appointmentVisit(circleId, value.id);
    unawaited(context.push<void>('$visit?fill=1', extra: true));
  }
}

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
