import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/normal_range_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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

  /// Opens the medical file, and reads the ranges again on the way back: a
  /// changed condition changes them.
  Future<void> _openMedicalFile(BuildContext context) async {
    final MeasurementRangesCubit cubit = context.read<MeasurementRangesCubit>();
    await context.push(Routes.medicalFile(circleId));
    if (!cubit.isClosed) await cubit.load(circleId);
  }

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
          final List<NormalRange> shown = <NormalRange>[
            if (kind == MeasurementKind.bp)
              ?ranges.of(MeasurementKind.bp)
            else
              for (final String group in _groups())
                ?ranges.of(MeasurementKind.glucose, group),
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final NormalRange range in shown) ...[
                if (range != shown.first) const SizedBox(height: 16),
                NormalRangeCard(
                  range: range,
                  footer: range == shown.last
                      ? context.tr('measurements.range_from_file')
                      : null,
                  action: range == shown.last
                      ? InsetRow(
                          label: context.tr('measurements.change_condition'),
                          leading: const Icon(AppIcons.fileText),
                          showChevron: true,
                          onTap: () => _openMedicalFile(context),
                        )
                      : null,
                ),
              ],
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
