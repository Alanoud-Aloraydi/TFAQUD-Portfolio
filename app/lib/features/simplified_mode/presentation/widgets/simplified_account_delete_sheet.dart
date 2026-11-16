import 'package:app/features/simplified_mode/presentation/widgets/simplified_account_delete_body.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

/// The first question of deleting, asked as a big sheet.
Future<bool?> confirmSimplifiedDelete(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    backgroundColor: SimplifiedStyle.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
        child: simplifiedDeleteSheetBody(sheetContext),
      ),
    ),
  );
}
