import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/core/widgets/layout/filtered_history.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/core/widgets/loading/skeleton_page.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_history_entry.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/domain/entities/medication_version.dart';
import 'package:app/features/medications/presentation/cubit/extra_dose_history_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_earlier.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_days.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_earlier.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_skeleton.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «سجل الجرعات» of one medicine, its extra doses among the others,
/// gathered in a box that folds away as «يحتاج انتباهك» does, with its
/// count. Two filters pick a day and who recorded; «أقدم» reads further
/// back.
class MedicationDoseHistory extends StatelessWidget {
  const MedicationDoseHistory({
    super.key,
    required this.earliest,
    required this.circleId,
    required this.medicine,
  });

  /// The medicine's first day: after today, the history says it starts.
  final DateTime earliest;

  final String circleId;
  final MedicationVersion medicine;

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<MedicationOccurrencesCubit, MedicationOccurrencesState>(
        // Only a failed «أقدم»: the answers to a dose show their own errors.
        listenWhen: (previous, current) =>
            current.messageKey != null &&
            previous.status == MedicationOccurrencesStatus.loadingMore,
        listener: (context, state) =>
            AppToast.show(context, state.messageKey!, kind: ToastKind.error),
        builder: (context, state) => switch (state.status) {
          MedicationOccurrencesStatus.loading => const DoseHistorySkeleton(),
          MedicationOccurrencesStatus.failure => RetryView(
            messageKey: state.messageKey!,
            onRetry: context.read<MedicationOccurrencesCubit>().reload,
          ),
          _ => DoseHistoryView(
            state: state,
            earliest: earliest,
            circleId: circleId,
            medicine: medicine,
          ),
        },
      );
}

/// The dose history inside a medicine's page while it loads: its title and
/// dose rows. It sits inside the page's scrolling list, so it does not
/// scroll itself.
class DoseHistorySkeleton extends StatelessWidget {
  const DoseHistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonBlock(
      children: <Widget>[
        SkeletonLine(widthFactor: 0.35, height: 24),
        SizedBox(height: AppSpacing.sm),
        DoseRowSkeleton(),
        Divider(height: AppSizes.divider),
        DoseRowSkeleton(),
      ],
    );
  }
}

/// The largest dose the stepper reaches.
const double maxDose = 999;

/// Half a tablet and half a millilitre are common; the other units count
/// whole capsules, drops, puffs and units.
double doseStep(DoseUnit unit) => switch (unit) {
  DoseUnit.tablet || DoseUnit.milliliter => 0.5,
  _ => 1,
};

/// The dose typed in the field, in western digits, or null while it is not
/// a number yet.
double? typedDose(String text) =>
    double.tryParse(ArabicDigits.toWesternDecimal(text.trim()));

/// One step up or down, on the step's grid: 1.2 tablets goes to 1.5 or 1.
double steppedDose(double? current, int direction, double step) {
  final double raw = (current ?? 0) + direction * step;
  return ((raw / step).round() * step).clamp(step, maxDose);
}

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
