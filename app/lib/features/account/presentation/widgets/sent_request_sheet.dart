import 'package:app/core/constants/app_colors.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/widgets/delete_dialogs.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/presentation/widgets/request_sent_view.dart';
import 'package:app/features/circles/presentation/widgets/status_pill.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// Opens the details of a request the account sent, with a button that cancels
/// it. The sheet is above the page, so it receives [cubit].
Future<void> showSentRequestSheet(
  BuildContext context, {
  required AccountCubit cubit,
  required SentCircleRequest request,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext sheetContext) =>
        _SentRequestSheet(cubit: cubit, request: request),
  );
}

class _SentRequestSheet extends StatelessWidget {
  const _SentRequestSheet({required this.cubit, required this.request});

  final AccountCubit cubit;
  final SentCircleRequest request;

  Future<void> _cancel(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final bool? yes = await showCancelRequestDialog(context);
    if (yes != true) return;
    final bool canceled = await cubit.cancelRequest(request.id);
    if (canceled) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool accepted = request.status == CircleRequestStatus.accepted;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                context.tr('account.request_sheet_title'),
                style: text.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            _Line(
              label: context.tr('circles.patient_phone_label'),
              child: Text(
                RequestSentView.displayPhone(request.patientPhoneNumber),
                textDirection: TextDirection.ltr,
                style: text.bodyMedium,
              ),
            ),
            _Line(
              label: context.tr('circles.label_title'),
              child: Text(request.circleLabel, style: text.bodyMedium),
            ),
            _Line(
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
            _Line(
              label: context.tr('circles.request_status'),
              child: StatusPill(
                icon: accepted ? Icons.check : Icons.schedule,
                text: context.tr(
                  accepted
                      ? 'account.status_accepted'
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _cancel(context),
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: AppColors.dangerInk,
                  side: const BorderSide(color: AppColors.danger),
                ),
                child: Text(context.tr('circles.cancel_request')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.ink2),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
