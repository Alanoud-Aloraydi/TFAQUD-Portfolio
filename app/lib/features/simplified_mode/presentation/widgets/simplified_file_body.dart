import 'package:app/core/localization/medical_texts.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_file_contacts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_weather.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_weather_tile.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the simplified file shows: the turning circle while it loads, the
/// reason it could not be loaded with «حاول مرة ثانية», else the answers
/// and the people to call.
List<Widget> simplifiedFileBody(BuildContext context, MedicalFileState state) =>
    switch (state.status) {
      MedicalFileStatus.loading => const <Widget>[LoadingNote()],
      MedicalFileStatus.failure => <Widget>[
        Text(
          context.tr(state.messageKey ?? 'error.unknown'),
          style: SimplifiedStyle.text(
            SimplifiedStyle.body,
            color: SimplifiedColors.ink,
          ),
        ),
        SimplifiedButton(
          label: context.tr('simplified_mode.try_again'),
          onPressed: context.read<MedicalFileCubit>().load,
        ),
      ],
      MedicalFileStatus.ready => <Widget>[
        SimplifiedFileFactsCard(file: state.file!),
        ...simplifiedFileContacts(context, state, state.file),
      ],
    };

/// The patient's answers, one big row under the other in a single card.
class SimplifiedFileFactsCard extends StatelessWidget {
  const SimplifiedFileFactsCard({super.key, required this.file});

  final MedicalFile file;

  @override
  Widget build(BuildContext context) {
    final List<(String, String)> rows = simplifiedFileRows(context, file);
    return SimplifiedCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SimplifiedStyle.pad,
        vertical: 4,
      ),
      child: Column(
        children: <Widget>[
          for (int index = 0; index < rows.length; index++)
            SimplifiedMedicalFileRow(
              label: rows[index].$1,
              value: rows[index].$2,
              last: index == rows.length - 1,
            ),
        ],
      ),
    );
  }
}

/// The patient's saved answers as label and value, in the order the
/// simplified file shows them.
List<(String, String)> simplifiedFileRows(
  BuildContext context,
  MedicalFile file,
) => <(String, String)>[
  (context.tr('simplified_mode.file.name'), file.patient.fullName),
  (
    context.tr('simplified_mode.file.birth_date'),
    formatBirthDate(context, file.patient.birthDate),
  ),
  (
    context.tr('simplified_mode.file.blood_type'),
    MedicalTexts.bloodType(context, file.profile.bloodType),
  ),
  (
    context.tr('simplified_mode.file.allergies'),
    MedicalTexts.allergies(context, file.profile.allergies),
  ),
  (
    context.tr('simplified_mode.file.conditions'),
    MedicalTexts.conditions(context, file.profile.conditions),
  ),
  (context.tr('simplified_mode.file.city'), file.patient.city),
];
