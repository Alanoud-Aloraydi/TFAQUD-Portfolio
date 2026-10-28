import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MedicationPlanCard extends StatelessWidget {
  const MedicationPlanCard({
    super.key,
    required this.circleId,
    required this.plan,
  });

  final String circleId;
  final MedicationPlan plan;

  @override
  Widget build(BuildContext context) {
    final version = plan.version;
    final subtitle = [
      '${formatMedicationNumber(version.strengthValue)} '
          '${version.strengthUnit.apiValue}',
      version.reason,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');
    final today = DateUtils.dateOnly(DateTime.now());
    final status = plan.isPreviousOn(today)
        ? _PlanState.previous
        : plan.isScheduledOn(today)
        ? _PlanState.scheduled
        : _PlanState.current;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => _openDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.medication_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      version.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  _PlanStatus(state: status),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.chevron_left),
                ],
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle),
              ],
              const SizedBox(height: AppSpacing.md),
              _InfoLine(
                icon: Icons.schedule_outlined,
                text: context.tr(
                  'medications.schedule_count',
                  args: [version.schedules.length.toString()],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              _InfoLine(
                icon: Icons.date_range_outlined,
                text: _period(context, version.startsOn, version.endsOn),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDetails(BuildContext context) async {
    final changed = await context.push<bool>(
      Routes.medicationDetails(circleId, plan.id),
    );
    if (!context.mounted) return;
    final updates = <Future<void>>[
      context.read<MedicationOccurrencesCubit>().reload(),
    ];
    if (changed == true) {
      updates.add(context.read<MedicationsCubit>().load(circleId));
    }
    await Future.wait(updates);
  }

  String _period(BuildContext context, DateTime start, DateTime? end) {
    if (end == null) {
      return context.tr(
        'medications.starts_on',
        args: [formatMedicationDate(context, start)],
      );
    }
    return context.tr(
      'medications.period',
      args: [
        formatMedicationDate(context, start),
        formatMedicationDate(context, end),
      ],
    );
  }
}

enum _PlanState { current, scheduled, previous }

class _PlanStatus extends StatelessWidget {
  const _PlanStatus({required this.state});

  final _PlanState state;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          context.tr('medications.${state.name}_label'),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}
