import 'package:app/features/simplified_mode/domain/entities/simplified_text_size.dart';
import 'package:app/features/simplified_mode/domain/repositories/simplified_settings_store.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the simplified mode's text size on this phone: it belongs to the
/// device, not the account.
@LazySingleton(as: SimplifiedSettingsStore)
class SimplifiedPreferences implements SimplifiedSettingsStore {
  static const String _textSizeKey = 'simplified_text_size';

  /// Where the earlier simplified mode kept its text size
  /// («small», «normal», «large»), read once so a choice is not lost.
  static const String _earlierTextSizeKey = 'simplified_text_scale';

  @override
  Future<SimplifiedTextSize> textSize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_textSizeKey);
    for (final SimplifiedTextSize size in SimplifiedTextSize.values) {
      if (size.name == saved) return size;
    }
    final String? earlier = prefs.getString(_earlierTextSizeKey);
    if (earlier == null) return SimplifiedTextSize.normal;
    final SimplifiedTextSize size = earlier == 'large'
        ? SimplifiedTextSize.large
        : SimplifiedTextSize.normal;
    await prefs.setString(_textSizeKey, size.name);
    await prefs.remove(_earlierTextSizeKey);
    return size;
  }

  @override
  Future<void> saveTextSize(SimplifiedTextSize size) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_textSizeKey, size.name);
  }
}
