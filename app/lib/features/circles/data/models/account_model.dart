import 'package:app/features/circles/domain/entities/account_summary.dart';

/// Reads the answer of GET /api/v1/accounts/me: `{"account": {...}}`. The
/// names, the phone number and the circle of the account's own care are kept.
class AccountModel {
  const AccountModel(this._entity);

  final AccountSummary _entity;

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    final account = json['account'] as Map<String, dynamic>;
    return AccountModel(
      AccountSummary(
        // The names are null until the account setup is finished.
        firstName: (account['first_name'] as String?) ?? '',
        lastName: (account['last_name'] as String?) ?? '',
        displayName: (account['display_name'] as String?) ?? '',
        phoneNumber: (account['phone_number'] as String?) ?? '',
        patientCircleId: account['patient_circle_id'] as String?,
      ),
    );
  }

  AccountSummary toEntity() => _entity;
}
