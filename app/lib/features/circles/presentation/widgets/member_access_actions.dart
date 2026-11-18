import 'package:app/core/feedback/app_toast.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Lets a member edit [area] («medications», …) or not, then tells the
/// leader how it went.
Future<void> changeMemberAccess(
  BuildContext context,
  String accountId, {
  required String area,
  required bool allowed,
}) async {
  final String? error = await context
      .read<CircleOverviewCubit>()
      .setMemberEditAccess(accountId, area: area, allowed: allowed);
  if (!context.mounted) return;
  if (error != null) {
    AppToast.show(context, error, kind: ToastKind.error);
    return;
  }
  AppToast.showText(
    ScaffoldMessenger.of(context),
    context.tr(
      allowed ? 'toast.editing_allowed' : 'toast.editing_paused',
      args: <String>[context.tr('circle_overview.area.$area')],
    ),
  );
}
