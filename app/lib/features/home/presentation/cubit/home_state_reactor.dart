import 'dart:async';

import 'package:app/app/router/routers.dart';
import 'package:app/app/services/push_registration.dart';
import 'package:app/app/services/signed_out.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/cubit/clinical_data_loader.dart';
import 'package:app/features/home/presentation/cubit/notification_tap_handler.dart';
import 'package:app/features/home/presentation/cubit/reminder_sync.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// What the shell does when the home data changes: reminders, the push
/// token, the sign-in and onboarding routes and loading the shown circle.
class HomeStateReactor {
  HomeStateReactor(this.clinical, this.reminders, this.taps, this.lastTab);

  final ClinicalDataLoader clinical;
  final ReminderSync reminders;
  final NotificationTapHandler taps;

  /// The tab shown before the last change of tab.
  int lastTab;
  String? _loadedCircleId;

  /// Whether this phone's push token was asked for in this sign-in.
  bool _pushStarted = false;

  void dispose() {
    taps.dispose();
    clinical.dispose();
  }

  void onState(BuildContext context, HomeState state) {
    final HomeEntity? data = state.data;
    if (state.status == HomeStatus.ready && data != null) {
      reminders.onHome(data);
      if (!_pushStarted) {
        // Circle updates from the server need the phone's push token. With
        // the free Apple account iOS gives none, and nothing happens.
        _pushStarted = true;
        unawaited(GetIt.I<PushRegistration>().start(accountId: data.accountId));
      }
      taps.onReady();
    }
    if (state.status == HomeStatus.signIn) {
      // The sign-in ended: nothing stays for a person who is not signed in.
      unawaited(forgetSignedOutPerson());
      context.go(Routes.auth);
    } else if (state.status == HomeStatus.onboarding) {
      context.go(Routes.onboarding);
    } else if (state.status == HomeStatus.ready && state.messageKey != null) {
      AppToast.show(context, state.messageKey!, kind: ToastKind.error);
    }
    final CareCircleSummary? selected = state.selectedCircle;
    if (state.status == HomeStatus.ready &&
        selected != null &&
        selected.id != _loadedCircleId) {
      _loadedCircleId = selected.id;
      clinical.load(selected);
    }
  }
}

enum HomeStatus { loading, ready, failure, signIn, onboarding }

/// The day on screen and which circle it belongs to.
class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.loading,
    this.data,
    this.selectedCircleId,
    this.messageKey,
  });

  final HomeStatus status;
  final HomeEntity? data;
  final String? selectedCircleId;
  final String? messageKey;

  /// The selected circle, with its patient's zone; null while loading.
  CareCircleSummary? get selectedCircle => data?.circles
      .where((circle) => circle.id == selectedCircleId)
      .firstOrNull;

  @override
  List<Object?> get props => [status, data, selectedCircleId, messageKey];
}
