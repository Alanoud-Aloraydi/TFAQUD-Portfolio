import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/circles/domain/entities/previous_notification.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/entities/received_invitation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The white card every item of the notifications page sits in.
class _InboxCard extends StatelessWidget {
  const _InboxCard({
    required this.avatarText,
    required this.avatarBackground,
    required this.avatarForeground,
    required this.title,
    required this.body,
    this.avatarCode,
    this.pill,
    this.actions,
  });

  final String avatarText;

  /// The person's avatar; their first letter ([avatarText]) without one.
  final String? avatarCode;
  final Color avatarBackground;
  final Color avatarForeground;
  final String title;
  final String body;
  final Widget? pill;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppSurfaces.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (avatarCodes.contains(avatarCode))
                PersonPhoto(
                  name: avatarText,
                  photoPath: '',
                  avatarCode: avatarCode,
                  size: AppSizes.avatar,
                )
              else
                Container(
                  width: AppSizes.avatar,
                  height: AppSizes.avatar,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: avatarBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    avatarText,
                    style: text.titleMedium?.copyWith(color: avatarForeground),
                  ),
                ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Semantics(
                      header: true,
                      child: Text(title, style: text.titleMedium),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      body,
                      style: text.bodyMedium?.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (pill != null) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                pill!,
              ],
            ],
          ),
          if (actions != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            actions!,
          ],
        ],
      ),
    );
  }
}

/// The first letter of a name for the round avatar.
String _initial(String name) {
  final String trimmed = name.trim();
  return trimmed.isEmpty ? '؟' : trimmed.characters.first;
}

StatusBadge _needsReplyPill(BuildContext context) => StatusBadge(
  icon: AppIcons.clock,
  text: context.tr('circles.needs_reply_pill'),
  tone: StatusTone.attention,
);

/// Accept and decline side by side. While [busy] the buttons are off.
class _ReplyButtons extends StatelessWidget {
  const _ReplyButtons({
    required this.acceptLabel,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final String acceptLabel;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: FilledButton(
            onPressed: busy ? null : onAccept,
            style: FilledButton.styleFrom(
              shape: const StadiumBorder(),
              minimumSize: const Size.fromHeight(44),
            ),
            child: busy
                ? const SizedBox(
                    width: AppSpacing.space5,
                    height: AppSpacing.space5,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppSemanticColors.onActionPrimary,
                    ),
                  )
                : Text(acceptLabel),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: OutlinedButton(
            onPressed: busy ? null : onDecline,
            style: OutlinedButton.styleFrom(
              shape: const StadiumBorder(),
              minimumSize: const Size.fromHeight(44),
              foregroundColor: AppSemanticColors.textPrimary,
              side: const BorderSide(
                color: AppSemanticColors.borderControlBase,
              ),
            ),
            child: Text(context.tr('circles.decline')),
          ),
        ),
      ],
    );
  }
}

/// An invitation to manage a circle, answered on the card.
class InvitationCard extends StatelessWidget {
  const InvitationCard({
    super.key,
    required this.invitation,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final ReceivedInvitation invitation;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final String? by = invitation.invitedByName;
    final String name = by ?? '';
    return _InboxCard(
      avatarText: _initial(name),
      avatarCode: invitation.invitedByAvatarCode,
      avatarBackground: AppSemanticColors.selectedSurface,
      avatarForeground: AppSemanticColors.textPrimary,
      title: context.tr('circles.invitation_title'),
      body: by == null || by.trim().isEmpty
          ? context.tr(
              'circles.invitation_body',
              args: <String>[invitation.circleName],
            )
          : context.tr(
              'circles.invitation_body_by',
              args: <String>[by, invitation.circleName],
            ),
      pill: _needsReplyPill(context),
      actions: _ReplyButtons(
        acceptLabel: context.tr('circles.accept'),
        busy: busy,
        onAccept: onAccept,
        onDecline: onDecline,
      ),
    );
  }
}

/// A request that asks the person to become the patient of a circle. The
/// button opens the page that explains it and takes the answer.
class RequestCard extends StatelessWidget {
  const RequestCard({super.key, required this.request, required this.onView});

  final ReceivedCircleRequest request;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return _InboxCard(
      avatarText: _initial(request.requesterName),
      avatarCode: request.requesterAvatarCode,
      avatarBackground: AppSemanticColors.selectedSurface,
      avatarForeground: AppSemanticColors.textPrimary,
      title: context.tr('circles.request_card_title'),
      body: context.tr(
        'circles.request_card_body',
        args: <String>[request.requesterName],
      ),
      pill: _needsReplyPill(context),
      actions: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onView,
          style: FilledButton.styleFrom(
            shape: const StadiumBorder(),
            minimumSize: const Size.fromHeight(44),
          ),
          child: Text(context.tr('circles.view_request')),
        ),
      ),
    );
  }
}

/// A request the person agreed to and has not finished: the basic data is
/// missing, so the circle does not exist yet.
class AcceptedRequestCard extends StatelessWidget {
  const AcceptedRequestCard({
    super.key,
    required this.request,
    required this.busy,
    required this.onContinue,
    required this.onCancel,
  });

  final ReceivedCircleRequest request;
  final bool busy;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return _InboxCard(
      avatarText: _initial(request.requesterName),
      avatarCode: request.requesterAvatarCode,
      avatarBackground: AppSemanticColors.selectedSurface,
      avatarForeground: AppSemanticColors.textPrimary,
      title: context.tr('circles.complete_card_title'),
      // The patient names the circle on the next page.
      body: context.tr(
        'circles.complete_card_body',
        args: <String>[request.requesterName],
      ),
      pill: _needsReplyPill(context),
      actions: Row(
        children: <Widget>[
          Expanded(
            child: FilledButton(
              onPressed: busy ? null : onContinue,
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                minimumSize: const Size.fromHeight(44),
              ),
              child: Text(context.tr('common.continue')),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: OutlinedButton(
              onPressed: busy ? null : onCancel,
              // Cancelling a request cannot be undone: the error red.
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                minimumSize: const Size.fromHeight(44),
                foregroundColor: AppSemanticColors.statusError,
                side: const BorderSide(
                  color: AppSemanticColors.borderControlBase,
                ),
              ),
              child: Text(context.tr('circles.cancel_request')),
            ),
          ),
        ],
      ),
    );
  }
}

/// An invitation or a request that was already answered (the bell's
/// «السابقة»): what it was and how it ended, who it was with, and how long
/// ago at the end of the first line, where a waiting one says «بانتظار
/// ردّك».
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
    return _InboxCard(
      avatarText: _initial(item.otherName ?? ''),
      avatarCode: item.otherAvatarCode,
      avatarBackground: item.accepted
          ? AppSemanticColors.selectedSurface
          : AppSemanticColors.borderSubtle,
      avatarForeground: item.accepted
          ? AppSemanticColors.textPrimary
          : context.tokens.textSecondary,
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
