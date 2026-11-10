/// The longest person names the API accepts (docs/api-contracts.md,
/// section 5), counted in Unicode code points as the server and the
/// `account` and `patient` tables count them.
///
/// One source for every page that types a person's name: onboarding, the
/// account page, and the patient pages of a circle.
abstract final class NameLimits {
  /// A first name or a last name.
  static const int name = 50;

  /// The short name other circle members see.
  static const int displayName = 30;
}
