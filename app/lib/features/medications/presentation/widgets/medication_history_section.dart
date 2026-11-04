import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/core/widgets/navigation/swipe_selection_area.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/widgets/medication_record_card.dart';
import 'package:app/features/medications/presentation/widgets/medication_skeletons.dart';
import 'package:app/features/medications/presentation/widgets/medication_state_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays the medication history section UI.
class MedicationHistorySection extends StatelessWidget {
  const MedicationHistorySection({
    super.key,
    required this.circleId,
    required this.header,
  });

  final String circleId;
  final Widget header;

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
        header,
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => _chooseFilter(context, state.recordFilter),
            icon: const Icon(CupertinoIcons.slider_horizontal_3),
            label: Text(
              context.tr('medications.filter.${state.recordFilter.name}'),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SwipeSelectionArea(
          onPrevious: () {
            final index = state.recordFilter.index;
            if (index > 0) {
              context.read<MedicationsCubit>().setRecordFilter(
                MedicationRecordFilter.values[index - 1],
              );
            }
          },
          onNext: () {
            final index = state.recordFilter.index;
            if (index < MedicationRecordFilter.values.length - 1) {
              context.read<MedicationsCubit>().setRecordFilter(
                MedicationRecordFilter.values[index + 1],
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (visible.isEmpty)
                Center(child: Text(context.tr('medications.no_records')))
              else
                for (final plan in visible) ...[
                  MedicationRecordCard(circleId: circleId, plan: plan),
                  const SizedBox(height: AppSpacing.md),
                ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _chooseFilter(
    BuildContext context,
    MedicationRecordFilter selected,
  ) async {
    final value = await showCupertinoModalPopup<MedicationRecordFilter>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        actions: [
          for (final filter in MedicationRecordFilter.values)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(sheetContext).pop(filter),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.tr('medications.filter.${filter.name}')),
                  if (filter == selected) const Icon(CupertinoIcons.check_mark),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: Text(context.tr('common.cancel')),
        ),
      ),
    );
    if (value != null && context.mounted) {
      context.read<MedicationsCubit>().setRecordFilter(value);
    }
  }
}
