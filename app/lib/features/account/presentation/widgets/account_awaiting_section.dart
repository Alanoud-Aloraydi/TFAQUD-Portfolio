import 'package:app/core/widgets/layout/settings_section.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/widgets/account_sent_request_row.dart';
import 'package:app/features/account/presentation/widgets/sent_request_sheet.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The requests this account sent that the patient has not answered yet.
/// Tapping one opens the sheet that can cancel it.
Widget accountAwaitingSection(
  BuildContext context, {
  required AccountCubit cubit,
  required List<SentCircleRequest> sent,
}) {
  return SettingsSection(
    title: context.tr('account.awaiting_title'),
    children: <Widget>[
      for (final SentCircleRequest request in sent)
        AccountSentRequestRow(
          request: request,
          onTap: () =>
              showSentRequestSheet(context, cubit: cubit, request: request),
        ),
    ],
  );
}
