import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/widgets/back_link.dart';
import 'package:app/core/widgets/glass.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Top of a step page: optional back link, title, optional subtitle.
///
/// A page that opens as a modal (it rises from the bottom, such as the
/// notifications and the account) has the close button (✕) in place of the
/// back link: [onClose] instead of [onBack].
class StepHeader extends StatelessWidget {
  const StepHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.onClose,
  }) : assert(onBack == null || onClose == null);

  final String title;
  final String? subtitle;

  /// Null hides the back link and keeps its space, so titles line up.
  final VoidCallback? onBack;

  /// The close button of a modal page, on the leading side (the right in
  /// Arabic), in glass as the buttons of the top bar.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (onClose != null)
          GlassIconButton(
            tooltip: context.tr('common.close'),
            icon: const Icon(CupertinoIcons.xmark),
            onPressed: onClose,
          )
        else if (onBack != null)
          BackLink(onPressed: onBack!)
        else
          const SizedBox(height: 44),
        const SizedBox(height: 12),
        Semantics(header: true, child: Text(title, style: text.headlineMedium)),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: text.bodyMedium?.copyWith(color: AppColors.slate),
          ),
        ],
      ],
    );
  }
}
