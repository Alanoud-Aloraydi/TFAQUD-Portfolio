import 'package:app/features/home/domain/export_filename.dart';
import 'package:app/features/home/domain/record_export_data.dart';
import 'package:app/features/home/presentation/cubit/record_export_cubit.dart';
import 'package:app/features/home/presentation/export/record_document.dart';
import 'package:app/features/home/presentation/widgets/record_export_confirm.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Asks to confirm what [data] holds, then shares it as a PDF. Returns
/// whether the file was shared.
Future<bool> confirmAndShareRecord(
  BuildContext context,
  RecordExportCubit cubit,
  RecordExportData data,
) async {
  if (await showRecordExportConfirm(context, data) != true ||
      !context.mounted) {
    return false;
  }
  // Read now: the footer is written after the page has awaited.
  final String pageTemplate = context.tr('record_export.page');
  return cubit.share(
    document: buildRecordDocument(context, data),
    pageLabel: (page, pages) =>
        pageTemplate.replaceFirst('{}', '$page').replaceFirst('{}', '$pages'),
    filename: exportFilename(data.medicalFile?.patient.fullName, data.period),
  );
}
