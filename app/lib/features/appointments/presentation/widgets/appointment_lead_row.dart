import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/overlays/glass_menu_item.dart';
import 'package:app/features/appointments/domain/appointment_reminder_lead.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// How long before the visit to be reminded, in «إضافة موعد».
///
/// Every visit is reminded twice: once the day before, which is fixed and
/// not asked about here, and once shortly before its time. That near one
/// was two hours for every visit — too early for the clinic downstairs,
/// too late for the one across the city — so it is chosen per visit, an
/// hour by default.
class AppointmentLeadRow extends StatelessWidget {
  const AppointmentLeadRow({
    super.key,
    required this.minutes,
    required this.onChanged,
  });

  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Builder(
    builder: (BuildContext anchor) => InsetRow(
      label: context.tr('appointments.remind_before'),
      value: appointmentLeadText(context, minutes),
      showChevron: true,
      onTap: () => _pick(anchor),
    ),
  );

  Future<void> _pick(BuildContext anchor) async {
    final String label = anchor.tr('appointments.remind_before');
    final int? chosen = await showGlassMenu<int>(
      anchorContext: anchor,
      semanticLabel: label,
      sections: <List<GlassMenuItem<int>>>[
        <GlassMenuItem<int>>[
          for (final int lead in appointmentLeadChoices)
            GlassMenuItem<int>(
              value: lead,
              label: appointmentLeadText(anchor, lead),
              selected: lead == minutes,
            ),
        ],
      ],
    );
    if (chosen != null) onChanged(chosen);
  }
}

/// «قبل ساعة», «قبل ساعتين», «قبل نصف ساعة».
String appointmentLeadText(BuildContext context, int minutes) =>
    context.tr('appointments.lead.$minutes');
