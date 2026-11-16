import 'package:app/core/navigation/routers.dart';
import 'package:app/features/home/presentation/controllers/home_shell_actions.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/home/presentation/cubit/home_state.dart';
import 'package:app/features/home/presentation/widgets/home_add_sheet.dart';
import 'package:app/features/home/presentation/widgets/home_body.dart';
import 'package:app/features/home/presentation/widgets/home_widget.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/shell/app_shell.dart';
import 'package:app/features/shell/widgets/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The shell with its top bar, the add button and the body of the tabs.
Widget homeShellView(
  BuildContext context,
  HomeState state,
  HomeCubit cubit,
  StatefulNavigationShell navigationShell,
) {
  return AppShell(
    navigationShell: navigationShell,
    topBar: AppTopBar(
      displayName: state.data?.displayName,
      avatarCode: state.data?.avatarCode,
      onPhotoSaved: cubit.refresh,
      circles: HomeWidget(
        state: state,
        onSelected: cubit.selectCircle,
        onAddCircle: state.status == HomeStatus.ready
            ? () => context.push(Routes.addCircle)
            : null,
      ),
      // A person with no circle yet can still have a request to answer.
      needsReply: context.select<InboxCubit, int>(
        (InboxCubit inbox) => inbox.state.inbox.needsReply,
      ),
      onNotifications: state.status == HomeStatus.ready
          ? () => openNotifications(context)
          : null,
    ),
    onAdd: state.selectedCircle?.canRecord ?? false
        ? () => showHomeAddSheet(context, circle: state.selectedCircle!)
        : null,
    body: HomeBody(
      state: state,
      tabs: navigationShell,
      onRetry: cubit.load,
      onCreateCircle: () => context.push(Routes.addCircle),
    ),
  );
}
