import 'package:easy_localization/easy_localization.dart';
import 'package:app/core/widgets/time_picker_sheet.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/pill_button.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:flutter/material.dart';

Future<DateTime?> selectTakenTime(
  BuildContext context,
  DateTime scheduledOn,
) async {
  final now = DateTime.now();
  final selected = await showTafaqodTimeSheet(
    context,
    initialTime: TimeOfDay.fromDateTime(now),
    title: context.tr('medications.actual_time'),
  );
  if (selected == null) return null;
  return DateTime(
    scheduledOn.year,
    scheduledOn.month,
    scheduledOn.day,
    selected.hour,
    selected.minute,
  );
}

Future<DoseRecordDraft?> selectSkippedDose(BuildContext context) =>
    showModalBottomSheet<DoseRecordDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _SkipDoseSheet(),
    );

class _SkipDoseSheet extends StatefulWidget {
  const _SkipDoseSheet();

  @override
  State<_SkipDoseSheet> createState() => _SkipDoseSheetState();
}

class _SkipDoseSheetState extends State<_SkipDoseSheet> {
  final _note = TextEditingController();
  DoseSkipReason? _reason;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
              context.tr('medications.skip_title'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(context.tr('medications.skip_reason_optional')),
            const SizedBox(height: AppSpacing.md),
            ...DoseSkipReason.values.map(_reasonTile),
            if (_reason == DoseSkipReason.other) ...[
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _note,
                maxLength: 250,
                decoration: InputDecoration(
                  labelText: context.tr('medications.skip_reason_note'),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            PillButton(
              label: context.tr('medications.skip_confirm'),
              onPressed: _confirm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _reasonTile(DoseSkipReason reason) {
    final selected = reason == _reason;
    return ListTile(
      minVerticalPadding: 0,
      onTap: () => setState(() => _reason = selected ? null : reason),
      title: Text(context.tr('medications.skip_reason.${reason.name}')),
      trailing: Icon(selected ? Icons.check_circle : Icons.circle_outlined),
    );
  }

  void _confirm() {
    final note = _note.text.trim();
    Navigator.pop(
      context,
      DoseRecordDraft(
        outcome: DoseOutcome.skipped,
        skipReasonCode: _reason?.apiValue,
        skipReasonNote: _reason == DoseSkipReason.other && note.isNotEmpty
            ? note
            : null,
      ),
    );
  }
}
