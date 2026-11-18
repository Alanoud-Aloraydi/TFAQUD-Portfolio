import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/account/presentation/widgets/sent_request_icon.dart';
import 'package:app/features/account/presentation/widgets/sent_request_pill.dart';
import 'package:app/features/account/presentation/widgets/sent_request_texts.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/request_age.dart';
import 'package:flutter/material.dart';

/// One circle that waits for the patient: the number it was sent to, how
/// long ago, and where it stands. The circle has no name yet: the patient
/// names it when they complete the request.
class AccountSentRequestRow extends StatelessWidget {
  const AccountSentRequestRow({
    super.key,
    required this.request,
    required this.onTap,
  });

  final SentCircleRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool accepted = request.status == CircleRequestStatus.accepted;
    final int? days = RequestAge.days(
      request.createdAt,
      PatientClockScope.of(context),
    );
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: MergeSemantics(
              child: Row(
                children: <Widget>[
                  const SentRequestIcon(),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: SentRequestTexts(request: request, days: days),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SentRequestPill(accepted: accepted),
                  const SizedBox(width: AppSpacing.xs),
                  // Mirrored on a right-to-left screen: it points to the end of the row.
                  Icon(ArrowIcons.forward, color: context.tokens.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
