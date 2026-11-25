import 'package:app/core/errors/failure.dart';
import 'package:app/features/account/presentation/cubit/account_loading.dart';
import 'package:app/features/account/presentation/cubit/account_state.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';

/// Changing the names on the account.
mixin AccountProfileSaving on AccountScope {
  /// Saves the three names. Returns null when they were saved, and the key of
  /// the message to show otherwise, so the sheet that asked can stay open.
  Future<String?> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
  }) async {
    final AccountSummary? current = state.account;
    final String first = firstName.trim();
    final String last = lastName.trim();
    final String display = displayName.trim();
    if (current == null || first.isEmpty || last.isEmpty || display.isEmpty) {
      return 'common.field_required';
    }
    final result = await profile.saveProfile(
      firstName: first,
      lastName: last,
      displayName: display,
    );
    if (isClosed) return null;
    return result.when(
      (_) {
        emit(
          state.copyWith(
            account: AccountSummary(
              firstName: first,
              lastName: last,
              displayName: display,
              phoneNumber: current.phoneNumber,
              patientCircleId: current.patientCircleId,
              birthDate: current.birthDate,
              city: current.city,
              avatarCode: current.avatarCode,
            ),
            noticeKey: 'account.saved',
          ),
        );
        // The first letter of the display name is on the top bar of the home
        // screen, which loads again.
        home.notifyCirclesChanged();
        return null;
      },
      (Failure failure) {
        if (endsSession(failure)) emit(state.copyWith(sessionEnded: true));
        return failure.messageKey;
      },
    );
  }
}
