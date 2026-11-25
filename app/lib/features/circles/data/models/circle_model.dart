import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/circle_app_mode.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';

/// Reads the answer of a circle call: `{"circle": {...}}`. Only the id and the
/// name are kept; the other pages read the rest when they need it.
///
/// `complete_creation`'s answer alone also carries `account_app_mode`: the
/// actor's own app mode right after it was committed, so the app can switch
/// shells immediately instead of waiting for the next sign-in. The other
/// answers leave it out and read as [CircleAppMode.detailed], the mode the
/// server commits a circle's creator to.
class CircleModel {
  const CircleModel(
    this._entity, {
    this.accountAppMode = CircleAppMode.detailed,
  });

  final CareCircleSummary _entity;
  final CircleAppMode accountAppMode;

  factory CircleModel.fromJson(Map<String, dynamic> json) {
    final circle = json['circle'] as Map<String, dynamic>;
    return CircleModel(
      CareCircleSummary(
        id: circle['id'] as String,
        name: circle['name'] as String,
      ),
      accountAppMode: CircleAppMode.parse(json['account_app_mode'] as String?),
    );
  }

  CareCircleSummary toEntity() => _entity;
}

/// Reads the answer of GET /api/v1/accounts/me: `{"account": {...}}`. The
/// names, the phone number, the birth date and city from onboarding and the
/// circle of the account's own care are kept.
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
        birthDate: DateTime.tryParse((account['birth_date'] as String?) ?? ''),
        city: account['city'] as String?,
        avatarCode: account['avatar_code'] as String?,
      ),
    );
  }

  AccountSummary toEntity() => _entity;
}
