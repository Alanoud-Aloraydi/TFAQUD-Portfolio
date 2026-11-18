import 'package:app/core/constants/app_icons.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

/// The «رجوع» button on top of a sub-screen.
class SimplifiedPageBack extends StatelessWidget {
  const SimplifiedPageBack({super.key, required this.backKey});

  /// «رجوع», or «إغلاق» for a screen that saves something.
  final String backKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SimplifiedStyle.page,
        8,
        SimplifiedStyle.page,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          TextButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            // In right-to-left, «back» points to the right.
            icon: const Icon(ArrowIcons.back, size: 24),
            label: Text(
              context.tr(backKey),
              style: SimplifiedStyle.label(SimplifiedStyle.body),
            ),
            style: TextButton.styleFrom(
              foregroundColor: SimplifiedColors.ink,
              minimumSize: const Size(0, SimplifiedStyle.touch),
            ),
          ),
        ],
      ),
    );
  }
}
