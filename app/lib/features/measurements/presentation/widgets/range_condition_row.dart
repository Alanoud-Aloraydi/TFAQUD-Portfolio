import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/overlays/glass_menu_item.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «الحالة» under «المعدل الطبيعي» of a reading: whether the patient has
/// diabetes (glucose) or high blood pressure, as the medical file says. A
/// tap opens the two choices; picking the other one saves it in the
/// medical file through the [MeasurementRangesCubit] above, which reads
/// the ranges again, so the card and the reading's level follow at once.
class RangeConditionRow extends StatefulWidget {
  const RangeConditionRow({
    super.key,
    required this.circleId,
    required this.range,
  });

  final String circleId;
  final NormalRange range;

  @override
  State<RangeConditionRow> createState() => _RangeConditionRowState();
}

class _RangeConditionRowState extends State<RangeConditionRow> {
  bool _saving = false;

  /// Why the last change was not saved. Shown in the row: a toast would
  /// sit under the sheet.
  String? _errorKey;

  /// The medical file's code this kind's ranges follow.
  String get _code =>
      widget.range.kind == MeasurementKind.bp ? 'hypertension' : 'diabetes';

  bool get _has => widget.range.profile != 'general';

  String _label(BuildContext context, {required bool has}) => context.tr(
    'measurements.range_profile.'
    '${has ? _code : '${widget.range.kind.name}_general'}',
  );

  Future<void> _pick(BuildContext anchor) async {
    final bool? has = await showGlassMenu<bool>(
      anchorContext: anchor,
      semanticLabel: anchor.tr('measurements.range_condition'),
      sections: <List<GlassMenuItem<bool>>>[
        <GlassMenuItem<bool>>[
          for (final bool value in const <bool>[false, true])
            GlassMenuItem<bool>(
              value: value,
              label: _label(anchor, has: value),
              selected: value == _has,
            ),
        ],
      ],
    );
    if (has == null || has == _has || !mounted) return;
    setState(() {
      _saving = true;
      _errorKey = null;
    });
    // Saved, the new choice shows in the row and the card above it.
    final String? errorKey = await context
        .read<MeasurementRangesCubit>()
        .setCondition(widget.circleId, _code, has: has);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _errorKey = errorKey;
    });
  }

  @override
  Widget build(BuildContext context) => Builder(
    builder: (BuildContext anchor) => InsetRow(
      label: context.tr('measurements.range_condition'),
      value: _label(context, has: _has),
      trailing: _saving
          ? const SizedBox.square(
              dimension: AppSizes.iconSmall,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(AppIcons.caretUpDown, size: AppSizes.iconSmall),
      onTap: _saving ? null : () => _pick(anchor),
      errorText: _errorKey == null ? null : context.tr(_errorKey!),
    ),
  );
}
