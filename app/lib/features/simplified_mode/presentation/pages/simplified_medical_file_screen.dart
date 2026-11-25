import 'package:app/app/router/routers.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/medical_texts.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:app/features/simplified_mode/presentation/widgets/measurement_verdict.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_message.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_file_contacts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_next_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_page.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_weather.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_weather_tile.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «الملف الطبي» in the simplified mode: the patient's answers in big rows
/// and the people to call. «تعديل» opens the detailed mode's edit page
/// inside the simplified mode, and «حفظ» or «رجوع» there lands here again.
class SimplifiedMedicalFileScreen extends StatelessWidget {
  const SimplifiedMedicalFileScreen({super.key, required this.circleId});

  final String circleId;

  Future<void> _edit(BuildContext context, MedicalFile file) async {
    final MedicalFileCubit cubit = context.read<MedicalFileCubit>();
    await context.push<void>(
      Routes.simplifiedMedicalFileEdit(circleId),
      extra: file,
    );
    if (!cubit.isClosed) await cubit.load();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<MedicalFileCubit, MedicalFileState>(
        listenWhen: (MedicalFileState before, MedicalFileState after) =>
            after.sessionEnded && !before.sessionEnded,
        listener: (BuildContext context, MedicalFileState state) =>
            context.go(Routes.auth),
        builder: (BuildContext context, MedicalFileState state) {
          final MedicalFile? file = state.file;
          return SimplifiedPage(
            title: context.tr('simplified_mode.file.title'),
            titleTrailing: file == null
                ? null
                : SimplifiedFileEditButton(
                    onPressed: () => _edit(context, file),
                  ),
            children: simplifiedFileBody(context, state),
          );
        },
      );
}

/// «✎ تعديل» beside the title, which opens the detailed mode's edit page
/// inside this mode. The pencil and the fill are the app's one edit
/// affordance (`EditAction`), at this mode's size.
class SimplifiedFileEditButton extends StatelessWidget {
  const SimplifiedFileEditButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    icon: Icon(ActionIcons.pencil, size: SimplifiedStyle.caption),
    style: FilledButton.styleFrom(
      backgroundColor: SimplifiedColors.accentTint,
      foregroundColor: SimplifiedColors.ink,
      minimumSize: const Size(0, SimplifiedStyle.touch),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
    ),
    label: Text(
      context.tr('simplified_mode.file.edit'),
      style: SimplifiedStyle.head(SimplifiedStyle.caption),
    ),
  );
}

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

/// «تم، شكرًا»: says exactly what was saved, and stays until the patient
/// goes back home.
class SimplifiedDoneScreen extends StatelessWidget {
  const SimplifiedDoneScreen({super.key, required this.message});

  final SimplifiedDoneMessage message;

  @override
  Widget build(BuildContext context) {
    final String saved = message.text(context);
    return _screen(context, saved, message.verdict(context));
  }

  Widget _screen(
    BuildContext context,
    String saved,
    MeasurementVerdict? verdict,
  ) {
    return Scaffold(
      backgroundColor: SimplifiedColors.doneGround,
      body: SizedBox.expand(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SimplifiedDoneContent(saved: saved, verdict: verdict),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SimplifiedStyle.page,
                  0,
                  SimplifiedStyle.page,
                  36,
                ),
                child: SimplifiedButton(
                  label: context.tr('simplified_mode.back_home'),
                  tone: SimplifiedButtonTone.dark,
                  onPressed: () => context.go(Routes.simplifiedMode),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The mark, «تم، شكرًا», what was saved and, for a reading, what it means.
class SimplifiedDoneContent extends StatelessWidget {
  const SimplifiedDoneContent({
    super.key,
    required this.saved,
    required this.verdict,
  });

  final String saved;
  final MeasurementVerdict? verdict;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SimplifiedDoneMark(size: 144),
        const SizedBox(height: 32),
        Text(
          context.tr('simplified_mode.done_title'),
          style: SimplifiedStyle.head(38),
        ),
        const SizedBox(height: 8),
        Text(
          saved,
          textAlign: TextAlign.center,
          style: SimplifiedStyle.text(
            SimplifiedStyle.title,
            weight: AppTextTheme.medium,
          ),
        ),
        // The reading is worth little without what it
        // means, which is the whole reason to measure.
        if (verdict case final MeasurementVerdict said)
          SimplifiedDoneVerdictRow(verdict: said),
      ],
    );
  }
}

/// What the saved reading means, in a word beside its mark.
class SimplifiedDoneVerdictRow extends StatelessWidget {
  const SimplifiedDoneVerdictRow({super.key, required this.verdict});

  final MeasurementVerdict verdict;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ExcludeSemantics(child: Icon(verdict.level.icon, size: 28)),
          const SizedBox(width: 8),
          Text(
            verdict.label,
            style: SimplifiedStyle.head(SimplifiedStyle.headline),
          ),
        ],
      ),
    );
  }
}
