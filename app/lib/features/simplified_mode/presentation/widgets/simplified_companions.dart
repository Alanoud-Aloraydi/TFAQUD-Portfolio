import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_person_chip.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Who comes along to a visit: «معك» and then each one, their photo
/// before their name.
class SimplifiedCompanions extends StatelessWidget {
  const SimplifiedCompanions({
    super.key,
    required this.circleId,
    required this.companions,
    this.onDark = false,
  });

  final String circleId;
  final List<AppointmentCompanion> companions;

  /// On the dark ground of a full-screen reminder, where it is centred.
  final bool onDark;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    alignment: onDark ? WrapAlignment.center : WrapAlignment.start,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: <Widget>[
      Text(
        context.tr('simplified_mode.with_you'),
        style: SimplifiedStyle.label(
          SimplifiedStyle.caption,
          color: onDark ? SimplifiedStyle.surface : SimplifiedStyle.muted,
        ),
      ),
      for (final AppointmentCompanion one in companions)
        SimplifiedPersonChip(
          circleId: circleId,
          accountId: one.id,
          name: one.name,
          avatarCode: one.avatarCode,
          onDark: onDark,
        ),
    ],
  );
}
