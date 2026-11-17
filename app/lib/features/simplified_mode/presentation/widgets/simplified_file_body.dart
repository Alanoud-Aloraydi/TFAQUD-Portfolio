import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_file_contacts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_file_facts_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
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
            color: SimplifiedStyle.ink,
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
