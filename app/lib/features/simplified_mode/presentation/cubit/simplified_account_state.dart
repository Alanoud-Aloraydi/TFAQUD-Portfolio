import 'package:equatable/equatable.dart';

enum SimplifiedAccountStatus { loading, ready, failure }

/// Holds the simplified account screen's presentation state.
class SimplifiedAccountState extends Equatable {
  const SimplifiedAccountState({
    this.status = SimplifiedAccountStatus.loading,
    this.displayName,
    this.avatarCode,
    this.circleId,
  });

  final SimplifiedAccountStatus status;
  final String? displayName;
  final String? avatarCode;
  final String? circleId;

  @override
  List<Object?> get props => [status, displayName, avatarCode, circleId];
}
