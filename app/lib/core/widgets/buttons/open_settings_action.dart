import 'dart:async';

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/services/permissions/app_settings_page.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// «افتح الإعدادات», the one way back from a refused permission, as a
/// chip — the same affordance as «✎ تعديل».
///
/// It was a bare text button under the warning sentence, which reads as
/// part of the sentence: nothing says it can be pressed, so the person
/// does not try. The chip's own surface does, and the export arrow says
/// the tap leaves the app. A tap that cannot open Settings says so too,
/// rather than looking like a button that does nothing.
class OpenSettingsAction extends StatelessWidget {
  const OpenSettingsAction({
    super.key,
    this.labelStyle,
    this.iconSize = AppSizes.iconSmall,
  });

  /// The simplified mode's larger words; null keeps the chip's own.
  final TextStyle? labelStyle;
  final double iconSize;

  @override
  Widget build(BuildContext context) => ActionChip(
    avatar: Icon(
      AppIcons.export,
      size: iconSize,
      color: AppSemanticColors.textPrimary,
    ),
    label: Text(context.tr('circle_overview.open_settings')),
    labelStyle: labelStyle,
    backgroundColor: AppSemanticColors.selectedSurface,
    side: BorderSide.none,
    onPressed: () => unawaited(_open(context)),
  );

  Future<void> _open(BuildContext context) async {
    // Taken before the await: the app leaves for Settings in between.
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String failed = context.tr('circle_overview.open_settings_failed');
    if (!await openAppSettingsPage()) {
      AppToast.showText(messenger, failed, kind: ToastKind.error);
    }
  }
}
