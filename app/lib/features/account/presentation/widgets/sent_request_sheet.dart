import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/widgets/sent_request_details.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// Opens the details of a request the account sent, with a button that cancels
/// it. The sheet is above the page, so it receives [cubit].
Future<void> showSentRequestSheet(
  BuildContext context, {
  required AccountCubit cubit,
  required SentCircleRequest request,
}) {
  return showGlassSheet<void>(
    context,
    title: context.tr('account.request_sheet_title'),
    builder: (BuildContext sheetContext) =>
        SentRequestDetails(cubit: cubit, request: request),
  );
}
