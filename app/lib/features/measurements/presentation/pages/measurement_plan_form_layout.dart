import 'package:app/app/router/care_item_routes.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/calendar_texts.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/info_row.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/features/measurements/domain/entities/measurement_conditions.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_plan.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/plan_schedule_draft.dart';
import 'package:app/features/measurements/presentation/pages/measurement_plan_form_saving.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_answer.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_form_schedule.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_readings_history.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The body of the plan form, from what the form holds.
mixin MeasurementPlanFormLayout
    on MeasurementPlanFormScope, MeasurementPlanFormReadings {
  Widget formBody(MeasurementPlan? plan, MeasurementPlan? existing) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        MeasurementPlanKindSection(
          kind: kind,
          isNew: plan == null,
          onChanged: (value) => edit(() => kind = value),
        ),
        if (existing != null) ...[
          const SizedBox(height: AppSpacing.md),
          MeasurementPlanExistingNotice(
            circleId: widget.circleId,
            planId: existing.id,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        MeasurementPlanFormSchedule(
          schedule: schedule,
          kind: kind,
          isNew: plan == null,
          missedAfterChecked: missedAfterChecked,
          errorKey: errorKey,
          onChanged: setState,
          onEdit: edit,
          onAdd: addReading,
        ),
        const SizedBox(height: AppSpacing.xl),
        MeasurementPlanFormRanges(
          cubit: ranges,
          circleId: widget.circleId,
          kind: kind,
          readings: readings,
        ),
        if (plan != null)
          MeasurementPlanFormNote(
            text: context.tr(
              'measurements.edit_effective_hint',
              args: [calendarDate(context, schedule.start)],
            ),
          ),
      ],
    );
  }
}

/// A line of text under the plan form: the hint about when an edit starts,
/// or the reason the form was not saved.
class MeasurementPlanFormNote extends StatelessWidget {
  const MeasurementPlanFormNote({super.key, required this.text, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Text(text, style: style),
  );
}

/// Adds a reading time to the schedule shown.
mixin MeasurementPlanFormReadings on MeasurementPlanFormScope {
  /// A new reading three hours after the last one (the same day), with the
  /// first «حالة القياس» of its kind not used yet.
  void addReading() {
    final TimeOfDay last = readings.last.time;
    final int next = last.hour * 60 + last.minute + 180;
    final int minutes = next > 23 * 60 ? 23 * 60 : next;
    final Set<String> used = {
      for (final item in readings) ?item.measurementState,
    };
    final String? meal = MeasurementConditions.planStates(kind)
        .where((String value) => !used.contains(value))
        .firstOrNull;
    edit(
      () => readings.add(
        PlanReadingDraft(
          TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
          meal,
        ),
      ),
    );
  }
}

/// «المعدل الطبيعي» of the plan form: fixed by the meal states of the
/// [readings] and the medical file, shown, not typed.
class MeasurementPlanFormRanges extends StatelessWidget {
  const MeasurementPlanFormRanges({
    super.key,
    required this.cubit,
    required this.circleId,
    required this.kind,
    required this.readings,
  });

  final MeasurementRangesCubit cubit;
  final String circleId;
  final MeasurementKind kind;
  final List<PlanReadingDraft> readings;

  @override
  Widget build(BuildContext context) =>
      BlocProvider<MeasurementRangesCubit>.value(
        value: cubit,
        child: MeasurementRangesBox(
          circleId: circleId,
          kind: kind,
          states: <String?>[for (final item in readings) item.measurementState],
        ),
      );
}

/// «المعدل الطبيعي» of a plan, from the [MeasurementRangesCubit] above: one
/// card per range its readings are judged by (glucose: fasting and after a
/// meal, as its reading [states] need), then where the condition comes from
/// and a row to change it in the medical file.
class MeasurementRangesBox extends StatelessWidget {
  const MeasurementRangesBox({
    super.key,
    required this.circleId,
    required this.kind,
    this.states = const <String?>[],
  });

  final String circleId;
  final MeasurementKind kind;

  /// The planned meal states of a glucose plan's reading times; none shows
  /// both glucose ranges.
  final List<String?> states;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<MeasurementRangesCubit, MeasurementRangesState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final NormalRanges? ranges = state.ranges;
          if (ranges == null) {
            // Tapping the message reads them again, as the lists retry.
            return TextButton(
              onPressed: () =>
                  context.read<MeasurementRangesCubit>().load(circleId),
              child: Text(context.tr(state.errorKey ?? 'error.unknown')),
            );
          }
          return MeasurementRangeCards(
            circleId: circleId,
            ranges: <NormalRange>[
              if (kind == MeasurementKind.bp)
                ?ranges.of(MeasurementKind.bp)
              else
                for (final String group in _groups())
                  ?ranges.of(MeasurementKind.glucose, group),
            ],
          );
        },
      );

  /// The glucose tables [states] need, fasting first; both when none.
  List<String> _groups() {
    final Set<String> used = {
      for (final String? state in states) normalRangeState(state),
    };
    return <String>[
      for (final String group in const <String>['fasting', 'after_meal'])
        if (used.isEmpty || used.contains(group)) group,
    ];
  }
}

/// «القياس» of the plan form: the kind to choose for a new plan.
///
/// The kind is chosen once, when the plan is made: an existing plan's
/// readings belong to it. Editing shows it as a fact, not as a control that
/// looks tappable and is not.
class MeasurementPlanKindSection extends StatelessWidget {
  const MeasurementPlanKindSection({
    super.key,
    required this.kind,
    required this.isNew,
    required this.onChanged,
  });

  final MeasurementKind kind;
  final bool isNew;
  final ValueChanged<MeasurementKind> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!isNew) {
      return InsetGroup(
        children: <Widget>[
          InfoRow(
            label: context.tr('measurements.measurement'),
            value: measurementKindTitle(context, kind),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.inset),
          child: Text(
            context.tr('measurements.measurement'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassSegmentedControl<MeasurementKind>(
          segments: <MeasurementKind, String>{
            MeasurementKind.glucose: context.tr('measurements.glucose'),
            MeasurementKind.bp: context.tr('measurements.bp'),
          },
          selected: kind,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Said when the kind already has an active plan: it is edited, not added
/// again. An action row: a pencil, the words, and a chevron.
class MeasurementPlanExistingNotice extends StatelessWidget {
  const MeasurementPlanExistingNotice({
    super.key,
    required this.circleId,
    required this.planId,
  });

  final String circleId;
  final String planId;

  @override
  Widget build(BuildContext context) => InsetGroup(
    footer: context.tr('measurements.active_plan_exists'),
    children: [
      InsetRow(
        label: context.tr('measurements.edit_plan'),
        leading: const Icon(ActionIcons.pencil),
        showChevron: true,
        onTap: () {
          final router = GoRouter.of(context);
          final path = CareItemRoutes.editMeasurement(circleId, planId);
          context.pop();
          router.push(path);
        },
      ),
    ],
  );
}
