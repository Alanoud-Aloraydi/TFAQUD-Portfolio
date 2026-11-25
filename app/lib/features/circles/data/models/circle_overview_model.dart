import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';

/// Maps the protected circle detail response to its display data.
class CircleOverviewModel {
  const CircleOverviewModel(this.overview);

  final CircleOverview overview;

  factory CircleOverviewModel.fromJson(Map<String, dynamic> response) {
    final circle = response['circle'] as Map<String, dynamic>;
    final patient = circle['patient'] as Map<String, dynamic>;
    final members = circle['members'] as List<dynamic>;
    final invitations =
        circle['pending_invitations'] as List<dynamic>? ?? <dynamic>[];
    return CircleOverviewModel(
      CircleOverview(
        name: circle['name'] as String,
        patientName: [
          patient['first_name'] as String,
          patient['last_name'] as String,
        ].join(' '),
        patientIsYou: patient['is_you'] as bool,
        patientUsesApp: patient['has_account'] as bool,
        patientAvatarCode: patient['avatar_code'] as String?,
        appMode: switch (patient['app_mode']) {
          final String mode => CircleAppMode.parse(mode),
          _ => null,
        },
        patientBirthDate: DateTime.parse(patient['birth_date'] as String),
        city: patient['city'] as String,
        canManage: circle['role'] == 'manager',
        canManageMembers: circle['can_manage_members'] as bool? ?? false,
        canHandOver: circle['can_hand_over'] as bool? ?? false,
        canLeave: circle['role'] == 'manager' || circle['role'] == 'member',
        members: <CircleMember>[
          for (final raw in members)
            CircleMember(
              name:
                  (raw as Map<String, dynamic>)['display_name'] as String? ??
                  '',
              isYou: raw['is_you'] as bool,
              isPatient: raw['is_patient'] as bool? ?? false,
              accountId: raw['account_id'] as String?,
              avatarCode: raw['avatar_code'] as String?,
              isManager: raw['role'] == 'manager',
              canEdit: raw['can_edit'] as bool? ?? raw['role'] == 'manager',
              isLeader: raw['is_leader'] as bool? ?? false,
              access: raw['edit_access'] == null
                  ? null
                  : EditAccess.fromJson(
                      raw['edit_access'],
                      fallback: raw['can_edit'] as bool? ?? false,
                    ),
              phoneNumber: raw['phone_number'] as String?,
            ),
        ],
        pendingInvitations: <CirclePendingInvitation>[
          for (final raw in invitations)
            CirclePendingInvitation(
              id: (raw as Map<String, dynamic>)['id'] as String,
              phoneNumber: raw['invitee_phone_number'] as String,
              createdAt: DateTime.parse(raw['created_at'] as String),
              lastSentAt: DateTime.tryParse(
                raw['last_sent_at'] as String? ?? '',
              ),
            ),
        ],
      ),
    );
  }
}

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
