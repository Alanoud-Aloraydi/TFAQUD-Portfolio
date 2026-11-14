import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_chip.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_round_answer.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The reminder itself.
class SimplifiedReminderBody extends StatelessWidget {
  const SimplifiedReminderBody({super.key, required this.content});

  final SimplifiedReminderContent content;

  @override
  Widget build(BuildContext context) {
    return _body(context);
  }

  Widget _body(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 44),
              child: Column(
                children: <Widget>[
                  Text(
                    content.brand,
                    style: SimplifiedStyle.text(
                      SimplifiedStyle.caption,
                      color: SimplifiedStyle.onDarkMuted,
                      weight: AppTextTheme.medium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 176,
                    height: 176,
                    decoration: BoxDecoration(
                      color: SimplifiedStyle.muted,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: SimplifiedStyle.attentionEdge,
                        width: 5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Center(child: content.hero),
                  ),
                  const SizedBox(height: 28),
                  Column(
                    children: <Widget>[
                      Text(
                        content.lead,
                        style: SimplifiedStyle.text(
                          28,
                          color: SimplifiedStyle.surface,
                        ),
                      ),
                      Text(
                        content.name,
                        textAlign: TextAlign.center,
                        style: SimplifiedStyle.head(
                          SimplifiedStyle.hero,
                          color: SimplifiedStyle.surface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        content.line,
                        textAlign: TextAlign.center,
                        style: SimplifiedStyle.head(
                          SimplifiedStyle.headline,
                          color: SimplifiedStyle.surface,
                        ),
                      ),
                      if (content.chips.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: <Widget>[
                            for (final String chip in content.chips)
                              SimplifiedChip(chip, onDark: true),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Spacer(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SimplifiedReminderRoundAnswer(
                        label: content.yesLabel,
                        icon: AppIcons.check,
                        fill: SimplifiedStyle.accent,
                        ink: SimplifiedStyle.ink,
                        onTap: content.onYes,
                      ),
                      if (content.onLater
                          case final VoidCallback later) ...<Widget>[
                        const SizedBox(width: 16),
                        SimplifiedReminderRoundAnswer(
                          label: context.tr('simplified_mode.remind_later'),
                          icon: AppIcons.clock,
                          fill: SimplifiedStyle.surface.withValues(alpha: .24),
                          ink: SimplifiedStyle.surface,
                          onTap: later,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
