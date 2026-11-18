import 'dart:async';

import 'package:app/core/media/private_photo_repository.dart';
import 'package:app/features/circles/presentation/cubit/inbox_cubit.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/controllers/clinical_data_reads.dart';
import 'package:app/features/home/presentation/controllers/home_state_reactor.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// The shell's reactions to the app coming back to the front and to a change
/// of tab.

/// Loads the home, the inbox, the reminders and the circle data again when
/// the app comes back to the front.
void refreshOnResume(BuildContext context, HomeStateReactor reactor) {
  // A circle member may have changed their photo on another phone while
  // this app was away. The home refresh below then reads every photo fresh.
  GetIt.I<PrivatePhotoRepository>().invalidateCache();
  // The page stays as it is while the data loads again in the background.
  unawaited(context.read<HomeCubit>().refresh());
  unawaited(context.read<InboxCubit>().load());
  reactor.reminders.refresh();
  final CareCircleSummary? circle = context
      .read<HomeCubit>()
      .state
      .selectedCircle;
  if (circle != null) reactor.clinical.load(circle, quiet: true);
}

/// A main page pulled down: the same as coming back to the front, done
/// once everything is back so the page's loader waits for it. Every read
/// is quiet: each part keeps what it shows until its own data is back. The
/// parts with data of their own read it on the scope's pull signal.
Future<void> refreshNow(BuildContext context, HomeStateReactor reactor) {
  GetIt.I<PrivatePhotoRepository>().invalidateCache();
  reactor.reminders.refresh();
  final HomeCubit home = context.read<HomeCubit>();
  final CareCircleSummary? circle = home.state.selectedCircle;
  return Future.wait(<Future<void>>[
    home.refresh(),
    context.read<InboxCubit>().load(),
    if (circle != null) reactor.clinical.reload(circle),
  ]);
}

/// Tells the circle data loader that the shown tab changed to [tab].
void syncTab(BuildContext context, HomeStateReactor reactor, int tab) {
  if (tab == reactor.lastTab) return;
  final CareCircleSummary? circle = context
      .read<HomeCubit>()
      .state
      .selectedCircle;
  reactor.clinical.tabChanged(reactor.lastTab, tab, circle);
  reactor.lastTab = tab;
}
