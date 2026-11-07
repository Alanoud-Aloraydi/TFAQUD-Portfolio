import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The simplified mode's own text-size choice, one step bigger than the
/// detailed mode's fixed scale at every step (see the design brief's
/// simplified type scale).
enum SimplifiedTextScale {
  small,
  normal,
  large;

  /// The factor applied over the simplified screens' own larger base
  /// sizes, so "normal" already reads bigger than the detailed mode.
  double get factor => switch (this) {
    SimplifiedTextScale.small => 0.9,
    SimplifiedTextScale.normal => 1.0,
    SimplifiedTextScale.large => 1.25,
  };
}

/// Persists the simplified mode's text-size choice on this phone; it is a
/// device setting, not an account one, like the calendar sync selections.
@lazySingleton
class SimplifiedTextScalePreference {
  static const String _key = 'simplified_text_scale';

  Future<SimplifiedTextScale> get() async {
    final prefs = await SharedPreferences.getInstance();
    final String? value = prefs.getString(_key);
    for (final scale in SimplifiedTextScale.values) {
      if (scale.name == value) return scale;
    }
    return SimplifiedTextScale.normal;
  }

  Future<void> set(SimplifiedTextScale scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, scale.name);
  }
}
