import 'package:app/core/widgets/buttons/open_settings_action.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// Why a feature cannot work, at this mode's sizes, with the one way back:
/// the phone's own Settings.
class SimplifiedPermissionDenied extends StatelessWidget {
  const SimplifiedPermissionDenied({super.key, required this.messageKey});

  /// The sentence above the button, such as
  /// `circle_overview.calendar_access_denied`.
  final String messageKey;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(
      top: 8,
      start: SimplifiedStyle.pad,
      end: SimplifiedStyle.pad,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.tr(messageKey),
          style: SimplifiedStyle.text(
            SimplifiedStyle.caption,
            color: SimplifiedStyle.attentionInk,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: OpenSettingsAction(
            labelStyle: SimplifiedStyle.label(SimplifiedStyle.body),
            iconSize: SimplifiedStyle.body,
          ),
        ),
      ],
    ),
  );
}
