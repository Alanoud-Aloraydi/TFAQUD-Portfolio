import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/entities/received_invitation.dart';
import 'package:app/features/circles/presentation/widgets/request_sent_view.dart';
import 'package:app/features/circles/presentation/widgets/status_pill.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The white card every item of the notifications page sits in.
class _InboxCard extends StatelessWidget {
  const _InboxCard({
    required this.avatarText,
    required this.avatarBackground,
    required this.avatarForeground,
    required this.title,
    required this.body,
    this.pill,
    this.extra,
    this.actions,
  });

  final String avatarText;
  final Color avatarBackground;
  final Color avatarForeground;
  final String title;
  final String body;
  final Widget? pill;

  /// A widget between the text and the buttons.
  final Widget? extra;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Semantics(
                      header: true,
                      child: Text(title, style: text.titleMedium),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: text.bodyMedium?.copyWith(color: AppColors.ink2),
                    ),
                  ],
                ),
              ),
              if (pill != null) ...<Widget>[const SizedBox(width: 8), pill!],
            ],
          ),
          if (extra != null) ...<Widget>[const SizedBox(height: 8), extra!],
          if (actions != null) ...<Widget>[
            const SizedBox(height: 12),
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

StatusPill _needsReplyPill(BuildContext context) => StatusPill(
  icon: Icons.schedule,
  text: context.tr('circles.needs_reply_pill'),
  background: AppColors.warningTint,
  foreground: AppColors.warningInk,
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
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.onBrand,
                    ),
                  )
                : Text(acceptLabel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: busy ? null : onDecline,
            style: OutlinedButton.styleFrom(
              shape: const StadiumBorder(),
              minimumSize: const Size.fromHeight(44),
              foregroundColor: AppColors.dangerInk,
              side: const BorderSide(color: AppColors.danger),
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
      avatarBackground: AppColors.successTint,
      avatarForeground: AppColors.successInk,
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
      avatarBackground: AppColors.brandTint,
      avatarForeground: AppColors.brand,
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
      avatarBackground: AppColors.brandTint,
      avatarForeground: AppColors.brand,
      title: context.tr('circles.complete_card_title'),
      body: context.tr(
        'circles.complete_card_body',
        args: <String>[request.requesterName, request.circleName],
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
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: busy ? null : onCancel,
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                minimumSize: const Size.fromHeight(44),
                foregroundColor: AppColors.dangerInk,
                side: const BorderSide(color: AppColors.danger),
              ),
              child: Text(context.tr('circles.cancel_request')),
            ),
          ),
        ],
      ),
    );
  }
}

/// The patient declined a request the signed-in person sent. The server keeps
/// it for a few days so that the sender learns of it.
class DeclinedRequestCard extends StatelessWidget {
  const DeclinedRequestCard({super.key, required this.request});

  final SentCircleRequest request;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return _InboxCard(
      avatarText: '!',
      avatarBackground: AppColors.dangerTint,
      avatarForeground: AppColors.dangerInk,
      title: context.tr('circles.declined_title'),
      body: context.tr(
        'circles.declined_body',
        args: <String>[request.circleLabel],
      ),
      extra: Text(
        RequestSentView.displayPhone(request.patientPhoneNumber),
        textDirection: TextDirection.ltr,
        style: text.bodyMedium?.copyWith(color: AppColors.ink3),
      ),
    );
  }
}
