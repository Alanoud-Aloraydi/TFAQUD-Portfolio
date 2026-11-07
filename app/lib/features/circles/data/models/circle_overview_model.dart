import 'package:app/features/circles/domain/entities/circle_overview.dart';

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
        appMode: patient['app_mode'] as String?,
        patientBirthDate: DateTime.parse(patient['birth_date'] as String),
        city: patient['city'] as String,
        canManage: circle['role'] == 'manager',
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
