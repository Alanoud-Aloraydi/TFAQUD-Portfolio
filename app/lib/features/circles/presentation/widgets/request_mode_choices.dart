import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/forms/choice_card.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «الوضع المقترح» and the two modes a request can propose for the
/// patient's app, as cards that each say what the mode means.
class RequestModeChoices extends StatelessWidget {
  const RequestModeChoices({
    super.key,
    required this.mode,
    required this.onChoose,
  });

  final CircleAppMode mode;
  final ValueChanged<CircleAppMode> onChoose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InsetText.header(context.tr('circles.proposed_mode')),
        const SizedBox(height: AppSpacing.sm),
        // Both modes and what each one means, on the screen at once.
        ChoiceCard(
          icon: PeopleIcons.user,
          title: context.tr('circles.mode_detailed'),
          hint: context.tr('circles.mode_detailed_hint'),
          selected: mode == CircleAppMode.detailed,
          onTap: () => onChoose(CircleAppMode.detailed),
        ),
        const SizedBox(height: AppSpacing.sm),
        ChoiceCard(
          icon: CareIcons.heart,
          title: context.tr('circles.mode_simplified'),
          hint: context.tr('circles.mode_simplified_hint'),
          selected: mode == CircleAppMode.simplified,
          onTap: () => onChoose(CircleAppMode.simplified),
        ),
      ],
    );
  }
}
