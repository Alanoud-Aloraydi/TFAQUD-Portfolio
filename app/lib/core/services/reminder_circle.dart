import 'package:equatable/equatable.dart';

/// A circle whose schedule reminds the person: its id, and the name the
/// reminder shows («أمي نورة»). Shared by the dose, measurement, and
/// appointment reminder schedulers, and by calendar sync.
class ReminderCircle extends Equatable {
  const ReminderCircle({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
