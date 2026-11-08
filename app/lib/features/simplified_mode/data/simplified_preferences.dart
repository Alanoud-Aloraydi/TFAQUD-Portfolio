import 'package:app/features/simplified_mode/domain/entities/simplified_text_size.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the simplified mode's text size and whether «استماع» shows, on
/// this phone: they are device settings, not account ones.
@lazySingleton
class SimplifiedPreferences {
  static const String _textSizeKey = 'simplified_text_size';
  static const String _voiceKey = 'simplified_voice_enabled';

  /// Where the earlier simplified mode kept its text size
  /// («small», «normal», «large»), read once so a choice is not lost.
  static const String _earlierTextSizeKey = 'simplified_text_scale';

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

  Future<void> saveTextSize(SimplifiedTextSize size) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_textSizeKey, size.name);
  }

  /// On until the person turns it off.
  Future<bool> voiceEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_voiceKey) ?? true;
  }

  Future<void> saveVoiceEnabled(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_voiceKey, enabled);
  }
}
