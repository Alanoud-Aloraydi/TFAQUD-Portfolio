/// A date the API sends without a time («YYYY-MM-DD»), or null.
DateTime? optionalApiDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

/// A moment the API sends in UTC, on this phone's clock, or null.
DateTime? optionalApiMoment(Object? value) =>
    value == null ? null : DateTime.parse(value as String).toLocal();
