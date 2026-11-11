import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/circles/presentation/cubit/inbox_state.dart';
import 'package:app/features/circles/presentation/widgets/notifications_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The notifications page: what needs an answer, then the requests that were
/// already answered. Needs an [InboxCubit] above it.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final InboxCubit cubit = context.read<InboxCubit>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: BlocConsumer<InboxCubit, InboxState>(
            listenWhen: (InboxState before, InboxState after) =>
                (after.sessionEnded && !before.sessionEnded) ||
                (after.errorKey != null && after.errorKey != before.errorKey),
            listener: _listen,
            builder: (BuildContext context, InboxState state) =>
                NotificationsBody(cubit: cubit, state: state),
          ),
        ),
      ),
    );
  }

  void _listen(BuildContext context, InboxState state) {
    if (state.sessionEnded) return context.go(Routes.auth);
    final String? key = state.errorKey;
    if (key == null) return;
    AppToast.show(context, key, kind: ToastKind.error);
    context.read<InboxCubit>().errorShown();
  }
}
