import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
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
      version.strength,
      version.reason,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');
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
    if (changed == true && context.mounted) {
      await context.read<MedicationsCubit>().load(circleId);
    }
  }

  String _period(BuildContext context, DateTime start, DateTime? end) {
    final formatter = DateFormat.yMd(context.locale.toString());
    if (end == null) {
      return context.tr(
        'medications.starts_on',
        args: [formatter.format(start)],
      );
    }
    return context.tr(
      'medications.period',
      args: [formatter.format(start), formatter.format(end)],
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
