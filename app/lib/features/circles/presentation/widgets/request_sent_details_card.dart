import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/feedback/status_pill.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/presentation/widgets/request_sent_detail_row.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// The number asked, the proposed mode and the status of the request.
class RequestSentDetailsCard extends StatelessWidget {
  const RequestSentDetailsCard({
    super.key,
    required this.request,
    required this.accepted,
  });

  final SentCircleRequest request;
  final bool accepted;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: AppSurfaces.card(),
      child: Column(
        children: <Widget>[
          RequestSentDetailRow(
            label: context.tr('circles.patient_phone_label'),
            child: Text(
              SaudiMobile.display(request.patientPhoneNumber),
              textDirection: TextDirection.ltr,
              style: text.bodyMedium,
            ),
          ),
          const Divider(height: AppSizes.divider),
          RequestSentDetailRow(
            label: context.tr('circles.app_mode'),
            child: StatusPill(
              text: context.tr(
                request.proposedAppMode == CircleAppMode.detailed
                    ? 'circles.mode_detailed'
                    : 'circles.mode_simplified',
              ),
              background: AppSemanticColors.selectedSurface,
              foreground: AppSemanticColors.textPrimary,
            ),
          ),
          const Divider(height: AppSizes.divider),
          RequestSentDetailRow(
            label: context.tr('circles.request_status'),
            child: StatusPill(
              icon: accepted ? AppIcons.check : AppIcons.clock,
              text: context.tr(
                accepted
                    ? 'circles.request_status_accepted'
                    : 'circles.request_status_pending',
              ),
              background: AppSemanticColors.background,
              foreground: accepted
                  ? AppSemanticColors.statusSuccess
                  : context.tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
