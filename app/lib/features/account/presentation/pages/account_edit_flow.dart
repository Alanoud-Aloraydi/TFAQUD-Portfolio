import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// What the name editor holds while it is open: the three names being typed,
/// whether the account filled them yet, the names left empty and the save in
/// flight.
mixin AccountEditFlow<T extends StatefulWidget> on State<T> {
  final first = TextEditingController();
  final last = TextEditingController();
  final display = TextEditingController();
  bool filled = false;
  bool saving = false;

  // After a save with a name left empty: «هذا الحقل مطلوب» under it.
  bool showErrors = false;

  @override
  void dispose() {
    first.dispose();
    last.dispose();
    display.dispose();
    super.dispose();
  }

  /// Puts the account's names in the fields, once.
  void fill(AccountSummary? account) {
    if (filled || account == null) return;
    first.text = account.firstName;
    last.text = account.lastName;
    display.text = account.displayName;
    filled = true;
  }

  /// Shows again what was typed, and the names still empty.
  void refresh() => setState(() {});

  /// «هذا الحقل مطلوب» under an empty name, after a save.
  String? requiredError(TextEditingController name) =>
      showErrors && name.text.trim().isEmpty
      ? context.tr('common.field_required')
      : null;

  Future<void> save() async {
    if (saving) return;
    final List<TextEditingController> names = [first, last, display];
    if (names.any((name) => name.text.trim().isEmpty)) {
      setState(() => showErrors = true);
      return;
    }
    setState(() => saving = true);
    final error = await context.read<AccountCubit>().saveProfile(
      firstName: first.text,
      lastName: last.text,
      displayName: display.text,
    );
    if (!mounted) return;
    if (error == null) {
      context.pop(true);
      return;
    }
    // About no one name: the server, or the connection.
    setState(() => saving = false);
    AppToast.show(context, error, kind: ToastKind.error);
  }
}
