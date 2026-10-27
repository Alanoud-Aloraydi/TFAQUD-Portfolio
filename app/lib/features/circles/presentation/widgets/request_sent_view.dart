import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/features/auth/presentation/widgets/phone_field.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/presentation/widgets/status_pill.dart';
// easy_localization also exports a TextDirection (from intl); hide it so the
// name means Flutter's TextDirection.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
                        ? AppColors.successTint
                        : AppColors.warningTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    accepted ? Icons.check : Icons.schedule,
                    size: 36,
                    color: accepted
                        ? AppColors.successInk
                        : AppColors.warningInk,
                  ),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    accepted
                        ? 'circles.request_accepted_body'
                        : 'circles.request_waiting_body',
                  ),
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: AppColors.ink2),
                ),
                const SizedBox(height: 24),
                _DetailsCard(request: request, accepted: accepted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go(Routes.today),
            style: OutlinedButton.styleFrom(
              shape: const StadiumBorder(),
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppColors.brand,
              side: const BorderSide(color: AppColors.brand),
            ),
            child: Text(context.tr('circles.request_back')),
          ),
        ),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.request, required this.accepted});

  final SentCircleRequest request;
  final bool accepted;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
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
          const Divider(height: 1),
          _DetailRow(
            label: context.tr('circles.app_mode'),
            child: StatusPill(
              text: context.tr(
                request.proposedAppMode == CircleAppMode.detailed
                    ? 'circles.mode_detailed'
                    : 'circles.mode_simplified',
              ),
              background: AppColors.brandTint,
              foreground: AppColors.brand,
            ),
          ),
          const Divider(height: 1),
          _DetailRow(
            label: context.tr('circles.request_status'),
            child: StatusPill(
              icon: accepted ? Icons.check : Icons.schedule,
              text: context.tr(
                accepted
                    ? 'circles.request_status_accepted'
                    : 'circles.request_status_pending',
              ),
              background: accepted
                  ? AppColors.successTint
                  : AppColors.warningTint,
              foreground: accepted
                  ? AppColors.successInk
                  : AppColors.warningInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(color: AppColors.ink2),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
