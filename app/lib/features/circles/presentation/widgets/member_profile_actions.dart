import 'dart:async';

import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/utils/phone_call.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// «اتصال» and «نسخ الرقم» under a member's number, in the order a contact
/// card has them on iPhone.
List<Widget> memberProfileActions(BuildContext context, String phone) =>
    <Widget>[
      const SizedBox(height: AppSpacing.lg),
      PillButton(
        label: context.tr('circle_overview.member_call'),
        onPressed: () => unawaited(callNumber(phone)),
      ),
      const SizedBox(height: AppSpacing.xs),
      TextButton.icon(
        onPressed: () => _copy(context, phone),
        icon: const Icon(CupertinoIcons.doc_on_doc, size: AppSizes.iconSmall),
        label: Text(context.tr('circle_overview.member_copy')),
      ),
    ];

void _copy(BuildContext context, String phone) {
  unawaited(Clipboard.setData(ClipboardData(text: phone)));
  HapticFeedback.selectionClick();
  AppToast.show(context, 'circle_overview.member_copied');
}
