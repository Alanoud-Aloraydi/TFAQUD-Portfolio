import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/feedback/status_pill.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/widgets/delete_dialogs.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
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
    useSafeArea: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (BuildContext sheetContext) =>
        _SentRequestSheet(cubit: cubit, request: request),
  );
}

/// Renders the sent request sheet element of sent request sheet.
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
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
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
            const SizedBox(height: AppSpacing.lg),
            _Line(
              label: context.tr('circles.patient_phone_label'),
              child: Text(
                SaudiMobile.display(request.patientPhoneNumber),
                textDirection: TextDirection.ltr,
                style: text.bodyMedium,
              ),
            ),
            _Line(
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
            _Line(
              label: context.tr('circles.request_status'),
              child: StatusPill(
                icon: accepted ? AppIcons.check : AppIcons.clock,
                text: context.tr(
                  accepted
                      ? 'account.status_accepted'
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
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _cancel(context),
                // Cancelling a request cannot be undone: the error red.
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  minimumSize: const Size.fromHeight(48),
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
      ),
    );
  }
}

/// Renders the line element of sent request sheet.
class _Line extends StatelessWidget {
  const _Line({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: context.tokens.textSecondary),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
