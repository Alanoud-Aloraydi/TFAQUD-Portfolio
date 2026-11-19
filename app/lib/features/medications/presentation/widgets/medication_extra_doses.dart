import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/extra_dose_history_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// «جرعات إضافية» on a medicine's page: what «سجّل جرعة الآن» recorded for
/// it, newest first, each with its time, amount and who recorded it.
/// Nothing at all while there is none.
class MedicationExtraDoses extends StatelessWidget {
  const MedicationExtraDoses({
    super.key,
    required this.circleId,
    required this.planId,
  });

  final String circleId;
  final String planId;

  @override
  Widget build(BuildContext context) {
    final PatientClock clock = PatientClockScope.of(context);
    return BlocProvider(
      create: (_) =>
          ExtraDoseHistoryCubit(GetIt.I<MedicationsUseCase>())
            ..load(circleId, planId, clock.today()),
      child: BlocBuilder<ExtraDoseHistoryCubit, List<ExtraDose>?>(
        builder: (BuildContext context, List<ExtraDose>? doses) {
          if (doses == null || doses.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            child: InsetGroup(
              header: context.tr('medications.extra_doses'),
              children: <Widget>[
                for (final ExtraDose dose in doses)
                  InsetRow(
                    label: formatMedicationDate(
                      context,
                      clock.wallTime(dose.takenAt),
                    ),
                    value: <String>[
                      wallTimeText(clock.wallTime(dose.takenAt)),
                      formatMedicationDose(
                        context,
                        dose.doseValue,
                        dose.doseUnit,
                      ),
                      ?dose.recordedByName,
                    ].join('، '),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
