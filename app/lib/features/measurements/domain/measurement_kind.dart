/// Defines the supported measurement kind values.
enum MeasurementKind {
  glucose,
  bp;

  /// What the server calls it: `glucose` or `blood_pressure`.
  String get wire => this == bp ? 'blood_pressure' : name;
}

/// Defines the supported measurement status values.
enum MeasurementStatus { upcoming, due, missed, read, readLate, skipped }

/// A kind or status this app does not know (sent by a newer server).
class UnknownMeasurementValue implements Exception {
  const UnknownMeasurementValue(this.value);

  /// The value as the server sent it.
  final Object? value;

  @override
  String toString() => 'UnknownMeasurementValue($value)';
}

/// [values] parsed by [parse], leaving out an item of a kind or status this
/// app does not know, so one newer item never hides the whole list.
List<T> knownMeasurementItems<T>(
  List<dynamic> values,
  T Function(Map<String, dynamic> json) parse,
) => <T>[
  for (final dynamic item in values)
    ?_known(() => parse(item as Map<String, dynamic>)),
];

T? _known<T>(T Function() parse) {
  try {
    return parse();
  } on UnknownMeasurementValue {
    return null;
  }
}

/// The kind the server named [value], or [UnknownMeasurementValue].
MeasurementKind measurementKindFromWire(Object? value) =>
    MeasurementKind.values.where((kind) => kind.wire == value).firstOrNull ??
    (throw UnknownMeasurementValue(value));

/// `read_late` → [MeasurementStatus.readLate].
MeasurementStatus measurementStatusFromWire(Object? value) =>
    MeasurementStatus.values.asNameMap()[value is String
        ? value.replaceAllMapped(
            RegExp('_([a-z])'),
            (match) => match[1]!.toUpperCase(),
          )
        : null] ??
    (throw UnknownMeasurementValue(value));
