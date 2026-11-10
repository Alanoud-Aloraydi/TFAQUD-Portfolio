/// The mode the patient's app opens in. The sender of a circle request proposes
/// one; the patient's account keeps it once the circle is created. [name] is
/// the value the API uses (`simplified`, `detailed`).
enum CircleAppMode {
  simplified,
  detailed;

  /// Reads the account's own app mode. Defaults to [detailed] because that
  /// is the only mode that existed before this field, so a missing or
  /// unrecognized value never silently switches an existing account.
  static CircleAppMode parse(String? value) =>
      value == 'simplified' ? CircleAppMode.simplified : CircleAppMode.detailed;
}
