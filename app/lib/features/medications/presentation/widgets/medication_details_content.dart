import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/core/widgets/buttons/edit_action.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/extra_dose_history_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/widgets/medication_details_body.dart';
import 'package:app/features/medications/presentation/widgets/medication_edit_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// The medicine's page: its own month of doses loaded beside it, and its
/// extra doses.
class MedicationDetailsContent extends StatelessWidget {
  const MedicationDetailsContent({
    super.key,
    required this.circleId,
    required this.plan,
    required this.canManage,
  });

  final String circleId;
  final MedicationPlan plan;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final today = PatientClockScope.of(context).today();
    // Calendar days, so a phone's own DST change never moves the range.
    final from = DateTime(today.year, today.month, today.day - 31);
    final start = plan.version.startsOn.isAfter(from)
        ? plan.version.startsOn
        : from;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => MedicationOccurrencesCubit(
            GetIt.I<MedicationsUseCase>(),
            photoChanges: GetIt.I<PrivatePhotoRepository>().changes,
          )..load(circleId, start, today, planId: plan.id),
        ),
        BlocProvider(
          create: (_) =>
              ExtraDoseHistoryCubit(GetIt.I<MedicationsUseCase>())
                ..load(circleId, plan.id, today),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('medications.details')),
          actions: [
            if (canManage && !plan.isPreviousOn(today))
              EditAction.pen(
                tooltip: context.tr('medications.edit_title'),
                onPressed: () => editMedication(context, circleId, plan.id),
              ),
          ],
        ),
        body: MedicationDetailsBody(
          circleId: circleId,
          plan: plan,
          canManage: canManage,
        ),
      ),
    );
  }
}
