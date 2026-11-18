import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/measurements/presentation/widgets/reading_error_note.dart';
import 'package:app/features/measurements/presentation/widgets/reading_note_group.dart';
import 'package:app/features/measurements/presentation/widgets/reading_time_group.dart';
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
