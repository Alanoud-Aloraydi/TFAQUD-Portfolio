import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/layout/filtered_history.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_history_entry.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';
import 'package:app/features/medications/domain/entities/medication_version.dart';
import 'package:app/features/medications/presentation/cubit/extra_dose_history_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_earlier.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_days.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_earlier.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The doses that were read, newest first, under the filter of «سجل
/// الجرعات», with «أقدم» under them while there is more to read: the doses
/// that had their time (one still ahead is not history yet), and the extra
/// doses of «سجّل جرعة الآن» of the same days, among them.
class DoseHistoryView extends StatelessWidget {
  const DoseHistoryView({
    super.key,
    required this.state,
    required this.earliest,
    required this.circleId,
    required this.medicine,
  });

  final MedicationOccurrencesState state;
  final DateTime earliest;
  final String circleId;

  /// The medicine, as its page shows it: the name of its extra doses.
  final MedicationVersion medicine;

  @override
  Widget build(BuildContext context) {
    final PatientClock clock = PatientClockScope.of(context);
    final DateTime now = clock.now();
    final List<ExtraDose> extras =
        context.watch<ExtraDoseHistoryCubit>().state ?? const <ExtraDose>[];
    return FilteredHistory<DoseHistoryEntry>(
      title: context.tr('medications.dose_history'),
      items: doseHistoryEntries(
        clock,
        doses: <DoseOccurrence>[
          for (final DoseOccurrence dose in state.occurrences)
            if (dose.isHistoryAt(now)) dose,
        ],
        extras: extras,
        medicine: medicine,
        from: context.read<MedicationOccurrencesCubit>().from,
      ),
      dayOf: (item) => item.day,
      byOf: (item) => item.recorder,
      empty: InsetText(doseHistoryEmptyText(context, earliest)),
      builder: (shown) => DoseHistoryDays(entries: shown, circleId: circleId),
      footer: DoseHistoryEarlier.orNull(context, state, earliest),
    );
  }
}

/// Why a medicine's dose history is empty: the treatment has not started
/// yet, or no dose was due in the days that were read.
String doseHistoryEmptyText(BuildContext context, DateTime earliest) =>
    earliest.isAfter(PatientClockScope.of(context).today())
    ? context.tr(
        'medications.dose_history_not_started',
        args: <String>[formatMedicationDate(context, earliest)],
      )
    : context.tr('medications.no_dose_history');
