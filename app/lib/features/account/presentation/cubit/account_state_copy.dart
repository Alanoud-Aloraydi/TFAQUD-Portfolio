import 'package:app/features/circles/domain/entities/account_deletion.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';

/// Replacing some of the fields of an [AccountState].
extension AccountStateCopy on AccountState {
  AccountState copyWith({
    AccountStatus? status,
    AccountSummary? account,
    List<CareCircleSummary>? circles,
    List<SentCircleRequest>? sent,
    String? messageKey,
    String? errorKey,
    String? noticeKey,
    bool clearMessages = false,
    Set<String>? busyIds,
    bool? deleting,
    DeletePrompt? deletePrompt,
    AccountDeletion? deletion,
    bool? signedOut,
    bool? sessionEnded,
  }) {
    return AccountState(
      status: status ?? this.status,
      account: account ?? this.account,
      circles: circles ?? this.circles,
      sent: sent ?? this.sent,
      messageKey: clearMessages ? null : (messageKey ?? this.messageKey),
      errorKey: clearMessages ? null : (errorKey ?? this.errorKey),
      noticeKey: clearMessages ? null : (noticeKey ?? this.noticeKey),
      busyIds: busyIds ?? this.busyIds,
      deleting: deleting ?? this.deleting,
      deletePrompt: deletePrompt ?? this.deletePrompt,
      deletion: deletion ?? this.deletion,
      signedOut: signedOut ?? this.signedOut,
      sessionEnded: sessionEnded ?? this.sessionEnded,
    );
  }
}
