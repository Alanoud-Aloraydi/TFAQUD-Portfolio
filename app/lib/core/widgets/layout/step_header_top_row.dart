import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/buttons/back_link.dart';
import 'package:app/core/widgets/navigation/glass_icon_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The top row of a [StepHeader]: close (✕) or back on the leading side,
/// or an empty space of the same height, and an optional [trailing] button
/// across from it.
class StepHeaderTopRow extends StatelessWidget {
  const StepHeaderTopRow({super.key, this.onBack, this.onClose, this.trailing});

  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (onClose != null)
          GlassIconButton(
            tooltip: context.tr('common.close'),
            icon: const Icon(ActionIcons.x),
            onPressed: onClose,
          )
        else if (onBack != null)
          BackLink(onPressed: onBack!)
        else
          const SizedBox(height: AppSizes.touch),
        if (trailing case final Widget end) ...<Widget>[const Spacer(), end],
      ],
    );
  }
}
