import 'package:app/core/errors/data_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_failures.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

/// The doses with the saved answer in place of the one that was asked
/// about. A dose is the schedule and the day together, so a medicine with
/// two times a day keeps them apart.
List<DoseOccurrence> withSavedRecord(
  List<DoseOccurrence> occurrences,
  DoseOccurrence answered,
  DoseRecord saved,
) => <DoseOccurrence>[
  for (final item in occurrences)
    if (item.scheduleId == answered.scheduleId &&
        item.scheduledOn == answered.scheduledOn)
      item.withRecord(saved)
    else
      item,
];

/// Whether the refusal means the list is behind: the dose was answered
/// elsewhere, or it is no longer in its plan.
bool isStaleDose(Failure failure) =>
    failure is ConflictFailure || failure is NotFoundFailure;

/// What to say about a refused answer: a dose that is gone says so in its
/// own words, anything else in the failure's.
String? doseRefusalKey(Failure failure) =>
    failure is NotFoundFailure ? 'medications.dose_gone' : failure.messageKey;
