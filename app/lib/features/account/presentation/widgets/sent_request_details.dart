import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/account/presentation/cubit/account_cubit.dart';
import 'package:app/features/account/presentation/widgets/delete_dialogs.dart';
import 'package:app/features/account/presentation/widgets/sent_request_line.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// What the sheet holds: the number, the mode, the status, and «إلغاء الطلب».
class SentRequestDetails extends StatelessWidget {
  const SentRequestDetails({required this.cubit, required this.request});

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
    // The glass sheet draws the title.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SentRequestLine(
          label: context.tr('circles.patient_phone_label'),
          child: Text(
            SaudiMobile.display(request.patientPhoneNumber),
            textDirection: TextDirection.ltr,
            style: text.bodyMedium,
          ),
        ),
        SentRequestLine(
          label: context.tr('circles.app_mode'),
          child: StatusBadge(
            text: context.tr(
              request.proposedAppMode == CircleAppMode.detailed
                  ? 'circles.mode_detailed'
                  : 'circles.mode_simplified',
            ),
            tone: StatusTone.success,
          ),
        ),
        SentRequestLine(
          label: context.tr('circles.request_status'),
          child: StatusBadge(
            icon: accepted ? AppIcons.check : AppIcons.clock,
            text: context.tr(
              accepted
                  ? 'account.status_accepted'
                  : 'circles.request_status_pending',
            ),
            tone: accepted ? StatusTone.success : StatusTone.attention,
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
    );
  }
}
