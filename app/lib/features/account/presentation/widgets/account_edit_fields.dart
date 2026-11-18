import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/features/account/presentation/widgets/account_name_fields.dart';
import 'package:app/features/account/presentation/widgets/account_phone_section.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The name editor's form: the first, last and display names, each a row
/// with «هذا الحقل مطلوب» under it when left empty, the display name's help
/// and the phone number read-only.
class AccountEditFields extends StatelessWidget {
  const AccountEditFields({
    super.key,
    required this.first,
    required this.last,
    required this.display,
    required this.phoneNumber,
    required this.requiredError,
    required this.onChanged,
  });

  final TextEditingController first;
  final TextEditingController last;
  final TextEditingController display;
  final String phoneNumber;

  /// The error under a name: «هذا الحقل مطلوب» when it is left empty.
  final String? Function(TextEditingController name) requiredError;

  /// Called when any of the names is typed in.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AccountNameFields(
            first: first,
            last: last,
            display: display,
            requiredError: requiredError,
            onChanged: onChanged,
          ),
          const SizedBox(height: AppSpacing.labelGap),
          InsetText.note(context.tr('account.display_name_help')),
          const SizedBox(height: AppSpacing.lg),
          AccountPhoneSection(phoneNumber: phoneNumber),
        ],
      ),
    );
  }
}
