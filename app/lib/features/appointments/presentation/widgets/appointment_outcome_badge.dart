import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/entities/appointment_outcome.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_card_status.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_kind_group.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_outcome_change.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A visit's badge in «السجل», pressed to change how it went
/// ([chooseAppointmentOutcome]); «قادم» is only read.
class AppointmentOutcomeBadge extends StatefulWidget {
  const AppointmentOutcomeBadge({
    super.key,
    required this.value,
    required this.circleId,
  });

  final CareAppointment value;
  final String circleId;

  @override
  State<AppointmentOutcomeBadge> createState() => _OutcomeBadgeState();
}

class _OutcomeBadgeState extends State<AppointmentOutcomeBadge> {
  /// The badge, where its menu grows from; hidden while the menu is open.
  final GlobalKey _badge = GlobalKey();
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final PatientClock clock = PatientClockScope.of(context);
    final CareAppointment value = widget.value;
    final List<AppointmentOutcome> choices = value.outcomesAt(clock.now());
    final Widget badge = AppointmentCardStatus(
      value: value,
      relative: false,
      trailing: choices.isEmpty ? null : ArrowIcons.caretDown,
    );
    if (choices.isEmpty) return badge;
    return Semantics(
      button: true,
      hint: context.tr('appointments.outcome_hint'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => chooseAppointmentOutcome(
          context,
          anchor: _badge.currentContext,
          circleId: widget.circleId,
          value: value,
          choices: choices,
          current: value.outcomeOn(clock.now(), clock.today()),
          badge: badge,
          open: (bool open) => mounted ? setState(() => _open = open) : null,
        ),
        // As tall as the card's line, so a finger finds it.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppItemCard.touch),
          child: Center(
            widthFactor: 1,
            child: Opacity(key: _badge, opacity: _open ? 0 : 1, child: badge),
          ),
        ),
      ),
    );
  }
}

/// Under an appointment card's day and time: «الزيارة 2 من 6» when it is one
/// of several dates booked together (counted among [all]), and its
/// «ورقة الزيارة» once it was attended.
List<Widget> appointmentCardBody(
  BuildContext context, {
  required CareAppointment value,
  required List<CareAppointment> all,
  required String circleId,
  required bool canManage,
}) => <Widget>[
  if (AppointmentSeries.of(value, all) case final AppointmentSeries at)
    Text(
      context.tr(
        'appointments.visit_of_series',
        args: <String>['${at.index}', '${at.count}'],
      ),
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: context.tokens.textSecondary),
    ),
  if (value.status == AppointmentStatus.completed)
    AppointmentVisitButton(
      visit: value,
      circleId: circleId,
      canManage: canManage,
    ),
];
