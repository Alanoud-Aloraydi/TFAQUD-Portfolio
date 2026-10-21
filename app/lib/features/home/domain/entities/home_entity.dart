import 'package:equatable/equatable.dart';

class CareCircleSummary extends Equatable {
  const CareCircleSummary({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

class HomeEntity extends Equatable {
  HomeEntity({
    required this.accountId,
    required this.displayName,
    required this.profileComplete,
    required List<CareCircleSummary> circles,
  }) : circles = List.unmodifiable(circles);

  final String accountId;
  final String? displayName;
  final bool profileComplete;
  final List<CareCircleSummary> circles;

  @override
  List<Object?> get props => [accountId, displayName, profileComplete, circles];
}
