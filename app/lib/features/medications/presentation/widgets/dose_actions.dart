import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/utils/text_limits.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/time_picker_sheet.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Asks when the dose of [scheduledOn] was taken and returns that moment.
/// The time picked is the patient's wall clock on that day, wherever this
/// phone is; the wheel starts at now on that clock.
///
/// [circleId] picks the words: «متى أخذت الجرعة؟» for the patient, «متى تم
/// أخذ الجرعة؟» for someone caring for them ([CareVoice]).
Future<DateTime?> selectTakenTime(
  BuildContext context,
  DateTime scheduledOn, {
  String? circleId,
}) async {
  final PatientClock clock = PatientClockScope.of(context);
  final selected = await showTafaqodTimeSheet(
    context,
    initialTime: TimeOfDay.fromDateTime(clock.now()),
    title: CareVoice.tr(context, circleId, 'medications.actual_time'),
  );
  if (selected == null) return null;
  return clock.momentOf(scheduledOn, '${selected.hour}:${selected.minute}');
}

Future<DoseRecordDraft?> selectSkippedDose(BuildContext context) =>
    showModalBottomSheet<DoseRecordDraft>(
      context: context,
      useSafeArea: true,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => const _SkipDoseSheet(),
    );

/// Renders the skip dose sheet element of dose actions.
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
                inputFormatters: const [CodePointLengthFormatter(250)],
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
      // As an iOS list: a check mark on the chosen reason, nothing on the
      // others.
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
