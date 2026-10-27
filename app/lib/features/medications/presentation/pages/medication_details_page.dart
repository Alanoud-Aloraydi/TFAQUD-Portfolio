import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/loading_widget.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_details.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_history.dart';
import 'package:app/features/medications/presentation/widgets/medication_state_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class MedicationDetailsPage extends StatelessWidget {
  const MedicationDetailsPage({
    super.key,
    required this.circleId,
    required this.planId,
  });

  final String circleId;
  final String planId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MedicationsCubit, MedicationsState>(
      builder: (context, state) {
        if (state.status == MedicationsStatus.loading) {
          return const Scaffold(body: LoadingWidget());
        }
        if (state.status == MedicationsStatus.failure || state.plans.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: MedicationFailureView(
              messageKey: state.messageKey ?? 'error.resource_not_found',
              onRetry: () =>
                  context.read<MedicationsCubit>().loadPlan(circleId, planId),
            ),
          );
        }
        return _Content(
          key: ValueKey(state.plans.first.version.number),
          circleId: circleId,
          plan: state.plans.first,
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({super.key, required this.circleId, required this.plan});

  final String circleId;
  final MedicationPlan plan;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final from = today.subtract(const Duration(days: 31));
    final start = plan.version.startsOn.isAfter(from)
        ? plan.version.startsOn
        : from;
    return BlocProvider(
      create: (_) =>
          MedicationOccurrencesCubit(GetIt.I<MedicationsUseCase>())
            ..load(circleId, start, today, planId: plan.id),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('medications.details')),
          actions: [
            IconButton(
              tooltip: context.tr('medications.edit_title'),
              onPressed: () => _edit(context),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            MedicationDetails(plan: plan),
            const SizedBox(height: AppSpacing.xl),
            MedicationDoseHistory(earliest: plan.version.startsOn),
            if (plan.discontinuedAt == null) ...[
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton(
                onPressed: () => _discontinue(context),
                child: Text(context.tr('medications.discontinue')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final changed = await context.push<bool>(
      Routes.editMedication(circleId, plan.id),
    );
    if (changed == true && context.mounted) {
      context.pop(true);
    }
  }

  Future<void> _discontinue(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('medications.discontinue_title')),
        content: Text(dialogContext.tr('medications.discontinue_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.tr('medications.discontinue_confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final changed = await context.read<MedicationsCubit>().discontinue(plan);
    if (!context.mounted) return;
    if (changed) {
      context.pop(true);
      return;
    }
    final message = context.read<MedicationsCubit>().state.messageKey;
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr(message))));
    }
  }
}
