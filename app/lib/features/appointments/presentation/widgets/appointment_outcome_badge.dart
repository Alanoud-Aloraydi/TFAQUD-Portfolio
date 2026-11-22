import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/appointment_outcome.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_card_status.dart';
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
