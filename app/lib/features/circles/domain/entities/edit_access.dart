import 'package:equatable/equatable.dart';

/// What a member may edit: the medicines, the measurements and the
/// appointments, each on its own. The circle's leader decides it.
class EditAccess extends Equatable {
  const EditAccess({
    required this.medications,
    required this.measurements,
    required this.appointments,
  });

  /// The same for all three.
  const EditAccess.all(bool allowed)
    : medications = allowed,
      measurements = allowed,
      appointments = allowed;

  /// The areas, as the API names them, in the order they show.
  static const List<String> areas = <String>[
    'medications',
    'measurements',
    'appointments',
  ];

  /// The `edit_access` of the API; [fallback] for each area it leaves out.
  factory EditAccess.fromJson(Object? json, {required bool fallback}) {
    final Map<String, dynamic> values = json is Map<String, dynamic>
        ? json
        : const <String, dynamic>{};
    bool read(String area) => values[area] as bool? ?? fallback;
    return EditAccess(
      medications: read('medications'),
      measurements: read('measurements'),
      appointments: read('appointments'),
    );
  }

  final bool medications;
  final bool measurements;
  final bool appointments;

  /// Whether [area] («medications», …) may be edited.
  bool of(String area) => switch (area) {
    'medications' => medications,
    'measurements' => measurements,
    _ => appointments,
  };

  /// Whether at least one area may be edited.
  bool get any => medications || measurements || appointments;

  @override
  List<Object?> get props => [medications, measurements, appointments];
}
