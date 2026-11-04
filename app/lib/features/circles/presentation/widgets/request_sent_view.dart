import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/widgets/feedback/status_pill.dart';
import 'package:app/core/widgets/forms/phone_field.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// easy_localization also exports a TextDirection (from intl); hide it so the
// name means Flutter's TextDirection.

/// The waiting state after a request is sent (CREAT-05): the circle does not
/// exist yet, and the page says who has to answer. The button goes back to the
/// home page.
class RequestSentView extends StatelessWidget {
  const RequestSentView({super.key, required this.request});

  final SentCircleRequest request;

  /// "+966501234567" is shown as "+966 50 123 4567", in English digits.
  static String displayPhone(String full) {
    const String code = '+966';
    final String digits = full.startsWith(code)
        ? full.substring(code.length)
        : full;
    return '$code ${PhoneNumberFormatter.display(digits)}';
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool accepted = request.status == CircleRequestStatus.accepted;
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 48),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: accepted
                        ? AppSemanticColors.surfaceContent
                        : AppSemanticColors.surfaceContent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    accepted ? AppIcons.check : AppIcons.clock,
                    size: AppSizes.iconEmpty,
                    color: accepted
                        ? AppSemanticColors.statusSuccess
                        : context.tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  header: true,
                  child: Text(
                    context.tr(
                      accepted
                          ? 'circles.request_accepted_title'
                          : 'circles.request_waiting_title',
                    ),
                    textAlign: TextAlign.center,
                    style: text.headlineMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.tr(
                    accepted
                        ? 'circles.request_accepted_body'
                        : 'circles.request_waiting_body',
                  ),
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: context.tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _DetailsCard(request: request, accepted: accepted),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go(Routes.today),
            style: OutlinedButton.styleFrom(
              shape: const StadiumBorder(),
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppSemanticColors.textPrimary,
              side: const BorderSide(
                color: AppSemanticColors.borderControlBase,
              ),
            ),
            child: Text(context.tr('circles.request_back')),
          ),
        ),
      ],
    );
  }
}

/// Renders the details card element of request sent view.
class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.request, required this.accepted});

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
          _DetailRow(
            label: context.tr('circles.patient_phone_label'),
            child: Text(
              RequestSentView.displayPhone(request.patientPhoneNumber),
              textDirection: TextDirection.ltr,
              style: text.bodyMedium,
            ),
          ),
          const Divider(height: AppSizes.divider),
          _DetailRow(
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
          _DetailRow(
            label: context.tr('circles.request_status'),
            child: StatusPill(
              icon: accepted ? AppIcons.check : AppIcons.clock,
              text: context.tr(
                accepted
                    ? 'circles.request_status_accepted'
                    : 'circles.request_status_pending',
              ),
              background: accepted
                  ? AppSemanticColors.background
                  : AppSemanticColors.background,
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

/// Renders the detail row element of request sent view.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(
                color: context.tokens.textSecondary,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
