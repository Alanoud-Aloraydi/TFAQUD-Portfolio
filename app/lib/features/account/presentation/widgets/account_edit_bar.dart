import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The top of the name editor: cancel, the title, and save, which waits
/// until the account is read and no save is running.
class AccountEditBar extends StatelessWidget {
  const AccountEditBar({super.key, required this.onSave});

  /// Null while saving is not possible.
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton(
          onPressed: () => context.pop(),
          child: Text(context.tr('common.cancel')),
        ),
        Expanded(
          child: Text(
            context.tr('account.edit_title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        FilledButton(
          onPressed: onSave,
          child: Text(context.tr('account.save')),
        ),
      ],
    );
  }
}
