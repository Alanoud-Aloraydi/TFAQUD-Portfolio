import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:app/features/measurements/presentation/widgets/reading_titles.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The end of the reading sheet: the time of the reading, the recorder's
/// note, and why the reading was not saved, when it was not ([errorKey]).
/// The server's refusal stays here, above the button: a toast would be
/// hidden behind the sheet.
class ReadingTimeAndNote extends StatelessWidget {
  const ReadingTimeAndNote({
    super.key,
    required this.time,
    required this.onPicked,
    required this.noteController,
    this.errorKey,
  });

  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onPicked;
  final TextEditingController noteController;
  final String? errorKey;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ReadingTimeGroup(time: time, onPicked: onPicked),
      const SizedBox(height: AppSpacing.lg),
      ReadingNoteGroup(controller: noteController),
      if (errorKey != null) ReadingErrorNote(errorKey: errorKey!),
    ],
  );
}

/// Why the reading was not saved, in the error colour.
class ReadingErrorNote extends StatelessWidget {
  const ReadingErrorNote({super.key, required this.errorKey});

  final String errorKey;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.sm),
    child: Text(
      context.tr(errorKey),
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}

/// «ملاحظة» of the reading sheet: a line of the recorder's own words.
class ReadingNoteGroup extends StatelessWidget {
  const ReadingNoteGroup({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => InsetGroup(
    children: [
      InsetTextRow(
        label: context.tr('measurements.note'),
        controller: controller,
        onChanged: (_) {},
        maxLength: 250,
      ),
    ],
  );
}
