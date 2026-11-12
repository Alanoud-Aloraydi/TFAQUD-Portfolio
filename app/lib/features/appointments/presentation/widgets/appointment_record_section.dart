import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/core/widgets/navigation/white_filter_menu.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/presentation/cubit/appointments_cubit.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The record tab's appointments, newest first, filtered by all, upcoming
/// or previous.
class AppointmentRecordSection extends StatefulWidget {
  const AppointmentRecordSection({
    super.key,
    required this.circleId,
    required this.header,
  });

  final String circleId;
  final Widget header;

  @override
  State<AppointmentRecordSection> createState() =>
      _AppointmentRecordSectionState();
}

class _AppointmentRecordSectionState extends State<AppointmentRecordSection> {
  static const List<String> _filters = <String>['all', 'upcoming', 'previous'];
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final AppointmentsState state = context.watch<AppointmentsCubit>().state;
    final DateTime now = PatientClockScope.of(context).now();
    final List<CareAppointment> values = state.appointments.where((item) {
      final bool upcoming =
          item.status == AppointmentStatus.scheduled &&
          !item.scheduledAt.isBefore(now);
      return _filter == 'all' || (_filter == 'upcoming') == upcoming;
    }).toList()..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return ListView(
      padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
      children: <Widget>[
        widget.header,
        const SizedBox(height: AppSpacing.md),
        WhiteFilterMenu<String>(
          options: <String, String>{
            for (final String key in _filters)
              key: context.tr('appointments.filters.$key'),
          },
          selected: _filter,
          onChanged: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.status == AppointmentsLoadStatus.loading && values.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (state.status == AppointmentsLoadStatus.failure)
          RetryView(
            messageKey: state.errorKey ?? 'error.unknown',
            onRetry: () =>
                context.read<AppointmentsCubit>().load(widget.circleId),
          )
        else if (values.isEmpty)
          EmptyStateNote(context.tr('appointments.no_records'))
        else
          for (final CareAppointment value in values) ...<Widget>[
            AppointmentCard(
              value: value,
              circleId: widget.circleId,
              canManage: false,
            ),
            const SizedBox(height: AppItemCard.listGap),
          ],
      ],
    );
  }
}
