import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/text_limits.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Future<MeasurementReadingDraft?> selectSkippedMeasurement(
  BuildContext context,
  MeasurementKind kind,
) => showModalBottomSheet<MeasurementReadingDraft>(
  context: context,
  useSafeArea: true,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => _SkipMeasurementSheet(kind: kind),
);

class _SkipMeasurementSheet extends StatefulWidget {
  const _SkipMeasurementSheet({required this.kind});

  final MeasurementKind kind;

  @override
  State<_SkipMeasurementSheet> createState() => _SkipMeasurementSheetState();
}

class _SkipMeasurementSheetState extends State<_SkipMeasurementSheet> {
  final _note = TextEditingController();
  MeasurementSkipReason? _reason;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('measurements.skip_title'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(context.tr('measurements.skip_reason_optional')),
          const SizedBox(height: AppSpacing.md),
          for (final reason in MeasurementSkipReason.values)
            _reasonTile(reason),
          if (_reason == MeasurementSkipReason.other) ...[
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _note,
              maxLength: 250,
              inputFormatters: const [CodePointLengthFormatter(250)],
              decoration: InputDecoration(
                labelText: context.tr('measurements.skip_reason_note'),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          PillButton(
            label: context.tr('measurements.skip_confirm'),
            onPressed: _confirm,
          ),
        ],
      ),
    ),
  );

  Widget _reasonTile(MeasurementSkipReason reason) {
    final selected = reason == _reason;
    return ListTile(
      minVerticalPadding: 0,
      onTap: () => setState(() => _reason = selected ? null : reason),
      title: Text(context.tr('measurements.skip_reason.${reason.name}')),
      selected: selected,
      trailing: selected
          ? const Icon(AppIcons.check, color: AppSemanticColors.textPrimary)
          : null,
    );
  }

  void _confirm() {
    final note = _note.text.trim();
    Navigator.pop(
      context,
      MeasurementReadingDraft(
        kind: widget.kind,
        outcome: 'skipped',
        skipReasonCode: _reason?.apiValue,
        skipReasonNote:
            _reason == MeasurementSkipReason.other && note.isNotEmpty
            ? note
            : null,
      ),
    );
  }
}

String measurementSkipReasonText(
  BuildContext context,
  MeasurementReading reading,
) {
  final code = reading.skipReasonCode;
  if (code == null) return '';
  if (code == 'other' && reading.skipReasonNote?.isNotEmpty == true) {
    return reading.skipReasonNote!;
  }
  final key = switch (code) {
    'equipment_unavailable' => 'equipmentUnavailable',
    'patient_refused' => 'patientRefused',
    _ => code,
  };
  return context.tr('measurements.skip_reason.$key');
}
