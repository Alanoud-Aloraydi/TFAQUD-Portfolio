import 'package:app/features/home/domain/entities/care_circle_summary.dart';
import 'package:equatable/equatable.dart';

export 'package:app/features/home/domain/entities/care_circle_summary.dart';

/// Represents home domain data.
class HomeEntity extends Equatable {
  HomeEntity({
    required this.accountId,
    required this.displayName,
    required this.profileComplete,
    this.avatarCode,
    required List<CareCircleSummary> circles,
  }) : circles = List.unmodifiable(circles);

  final String accountId;
  final String? displayName;
  final bool profileComplete;
  final String? avatarCode;
  final List<CareCircleSummary> circles;

  @override
  List<Object?> get props => [
    accountId,
    displayName,
    profileComplete,
    avatarCode,
    circles,
  ];
}
