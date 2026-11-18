import 'package:equatable/equatable.dart';

/// Identifies a circle member accompanying an appointment, or who added or
/// changed one.
class AppointmentCompanion extends Equatable {
  const AppointmentCompanion({
    required this.id,
    required this.name,
    this.avatarCode,
  });

  final String id;
  final String name;
  final String? avatarCode;

  @override
  List<Object?> get props => [id, name, avatarCode];
}
