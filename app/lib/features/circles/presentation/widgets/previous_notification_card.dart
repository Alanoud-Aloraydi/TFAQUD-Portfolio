import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/circles/domain/entities/previous_notification.dart';
import 'package:app/features/circles/presentation/widgets/inbox_avatar.dart';
import 'package:app/features/circles/presentation/widgets/inbox_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// An invitation or a request that was already answered (the bell's
/// «السابقة»): what it was, how it ended, who it was with, and how long ago
/// where a waiting one says «بانتظار ردّك».
class PreviousNotificationCard extends StatelessWidget {
  const PreviousNotificationCard({super.key, required this.item});

  final PreviousNotification item;

  @override
  Widget build(BuildContext context) {
    final PatientClock clock = PatientClockScope.of(context);
    // Days on the patient's calendar, never the phone's zone.
    final int days = clock
        .today()
        .difference(clock.today(item.answeredAt))
        .inDays;
    final String key =
        'circles.previous.${item.kind.name}_'
        '${item.accepted ? 'accepted' : 'declined'}';
    return InboxCard(
      avatar: InboxAvatar(
        name: item.otherName ?? '',
        avatarCode: item.otherAvatarCode,
        background: item.accepted
            ? AppSemanticColors.selectedSurface
            : AppSemanticColors.borderSubtle,
        foreground: item.accepted
            ? AppSemanticColors.textPrimary
            : context.tokens.textSecondary,
      ),
      title: context.tr('$key.title'),
      body: context.tr(
        '$key.body',
        args: <String>[
          _who(context),
          item.circleName ?? context.tr('circles.previous.a_circle'),
        ],
      ),
      pill: StatusBadge(
        icon: AppIcons.clock,
        text: daysAgo(context, days),
        tone: StatusTone.neutral,
      ),
    );
  }

  /// The other person: their name, else their number (read left to right
  /// inside the Arabic sentence), else «شخص».
  String _who(BuildContext context) {
    final String name = item.otherName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    final String? phone = item.otherPhoneNumber;
    if (phone == null) return context.tr('circles.previous.someone');
    return '\u2066${SaudiMobile.display(phone)}\u2069';
  }
}
