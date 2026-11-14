import 'package:equatable/equatable.dart';

/// An invitation to manage a circle, sent to the number of the signed-in
/// account (CIRCLE-02). The circle id is not shown before the invitation is
/// accepted.
class ReceivedInvitation extends Equatable {
  const ReceivedInvitation({
    required this.id,
    required this.circleName,
    this.invitedByName,
    this.invitedByAvatarCode,
    this.createdAt,
  });

  final String id;
  final String circleName;

  /// The display name of the manager who invited, when the server knows it.
  final String? invitedByName;

  /// Their avatar, shown beside their name.
  final String? invitedByAvatarCode;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
    id,
    circleName,
    invitedByName,
    invitedByAvatarCode,
    createdAt,
  ];
}
