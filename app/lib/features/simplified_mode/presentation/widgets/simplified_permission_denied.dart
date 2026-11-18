import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

/// Why a feature cannot work, at this mode's sizes, under its switch. As
/// in the detailed mode, the way back is the switch itself: turned on, it
/// says so and leaves for the phone's Settings (`leaveForSettings`).
class SimplifiedPermissionDenied extends StatelessWidget {
  const SimplifiedPermissionDenied({super.key, required this.messageKey});

  /// The sentence, such as `circle_overview.calendar_access_denied`.
  final String messageKey;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(
      top: 8,
      start: SimplifiedStyle.pad,
      end: SimplifiedStyle.pad,
    ),
    child: Text(
      context.tr(messageKey),
      style: SimplifiedStyle.text(
        SimplifiedStyle.caption,
        color: SimplifiedColors.attentionInk,
      ),
    ),
  );
}
