import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/core/widgets/layout/large_title.dart';
import 'package:app/features/home/presentation/widgets/home_category_control.dart';
import 'package:app/features/home/presentation/widgets/record_export_sheet.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_record_card.dart';
import 'package:app/features/medications/presentation/widgets/medication_skeletons.dart';
import 'package:app/features/medications/presentation/widgets/medication_state_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MedicationHistorySection extends StatelessWidget {
  const MedicationHistorySection({super.key, required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MedicationsCubit, MedicationsState>(
      builder: (context, state) => ContentSwitcher(
        // Only loading, error and content fade; saving a change does not.
        stateKey: switch (state.status) {
          MedicationsStatus.initial || MedicationsStatus.loading => 'loading',
          MedicationsStatus.failure => 'failure',
          _ => 'content',
        },
        child: _content(context, state),
      ),
    );
  }

  Widget _content(BuildContext context, MedicationsState state) {
    if (state.status == MedicationsStatus.initial ||
        state.status == MedicationsStatus.loading) {
      return const PlansSkeleton(filter: true);
    }
    if (state.status == MedicationsStatus.failure) {
      return MedicationFailureView(
        messageKey: state.messageKey!,
        onRetry: () => context.read<MedicationsCubit>().load(circleId),
      );
    }
    final today = DateUtils.dateOnly(DateTime.now());
    final current = state.plans
        .where((plan) => !plan.isPreviousOn(today))
        .toList();
    final previous = state.plans
        .where((plan) => plan.isPreviousOn(today))
        .toList();
    final visible = switch (state.recordFilter) {
      MedicationRecordFilter.all => state.plans,
      MedicationRecordFilter.current => current,
      MedicationRecordFilter.previous => previous,
    };
    return ListView(
      padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
      children: [
        Row(
          children: [
            Expanded(child: LargeTitle(title: context.tr('tab.record'))),
            TextButton.icon(
              onPressed: () => showRecordExportSheet(
                context,
                circleId: circleId,
                plans: state.plans,
              ),
              icon: const Icon(AppIcons.export),
              label: Text(context.tr('record_export.share_action')),
            ),
          ],
        ),
        HomeCategoryControl(medicationCount: state.plans.length),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final filter in MedicationRecordFilter.values)
              ChoiceChip(
                label: Text(context.tr('medications.filter.${filter.name}')),
                selected: state.recordFilter == filter,
                selectedColor: AppSemanticColors.textPrimary,
                backgroundColor: AppSemanticColors.surfaceContent,
                labelStyle: TextStyle(
                  color: state.recordFilter == filter
                      ? AppSemanticColors.surfaceContent
                      : AppSemanticColors.textPrimary,
                ),
                onSelected: (_) =>
                    context.read<MedicationsCubit>().setRecordFilter(filter),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        if (visible.isEmpty)
          Center(child: Text(context.tr('medications.no_records')))
        else
          for (final plan in visible) ...[
            MedicationRecordCard(circleId: circleId, plan: plan),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}
