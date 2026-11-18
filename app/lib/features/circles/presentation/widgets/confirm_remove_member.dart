import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/circles/domain/entities/circle_member.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/widgets/member_action_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Asks the leader to confirm, then removes the member from the circle.
Future<void> confirmRemoveMember(
  BuildContext context,
  CircleMember member,
  String accountId,
) async {
  final bool? confirmed = await showAppAlert<bool>(
    context,
    title: context.tr('circle_overview.remove_member_title'),
    message: context.tr(
      'circle_overview.remove_member_message',
      args: <String>[member.name],
    ),
    actions: <AppAlertAction<bool>>[
      AppAlertAction<bool>(label: context.tr('common.cancel'), value: false),
      AppAlertAction<bool>(
        label: context.tr('circle_overview.remove_member'),
        value: true,
        destructive: true,
      ),
    ],
  );
  if (confirmed != true || !context.mounted) return;
  final String? error = await context.read<CircleOverviewCubit>().removeMember(
    accountId,
  );
  if (!context.mounted) return;
  showMemberActionResult(context, error, 'toast.member_removed');
}
