import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/widgets/leave_circle_alert.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// «مغادرة الدائرة»: for the last manager and the patient it deletes the
/// circle instead, after a confirmation. A member whose editing is paused
/// can leave too.
class LeaveCircleButton extends StatelessWidget {
  const LeaveCircleButton({super.key, required this.overview});

  final CircleOverview overview;

  @override
  Widget build(BuildContext context) {
    final bool acting = context.select(
      (CircleOverviewCubit cubit) => cubit.state.acting,
    );
    return TextButton.icon(
      onPressed: acting ? null : () => _leave(context),
      style: TextButton.styleFrom(
        foregroundColor: AppSemanticColors.statusError,
        minimumSize: const Size.fromHeight(AppSizes.button),
      ),
      icon: const Icon(AppIcons.signOut, size: AppSizes.iconSmall),
      label: Text(context.tr('circle_overview.leave')),
    );
  }

  Future<void> _leave(BuildContext context) async {
    final bool deletesCircle = overview.leaveDeletesCircle;
    if (await askLeaveConfirmation(context, deletesCircle) != true) return;
    if (!context.mounted) return;
    final String? error = await context.read<CircleOverviewCubit>().leave(
      confirmDelete: deletesCircle,
    );
    if (!context.mounted) return;
    if (error != null) {
      AppToast.show(context, error, kind: ToastKind.error);
      return;
    }
    await context.read<HomeCubit>().refresh();
    if (!context.mounted) return;
    AppToast.show(context, 'toast.circle_left');
    context.go(Routes.today);
  }
}
