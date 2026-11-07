import 'package:flutter_tts/flutter_tts.dart';
import 'package:injectable/injectable.dart';

/// Reads text aloud for the simplified mode's «استماع» button, using the
/// phone's own Arabic voice (no network call, no API key).
@lazySingleton
class SimplifiedVoice {
  SimplifiedVoice() {
    _tts
      ..setLanguage('ar-SA')
      ..setSpeechRate(0.45);
  }

  final FlutterTts _tts = FlutterTts();

  /// Speaks [segments] one after another, stopping whatever it was saying.
  Future<void> speak(List<String> segments) async {
    await _tts.stop();
    await _tts.speak(segments.where((text) => text.isNotEmpty).join('. '));
  }

  Future<void> stop() => _tts.stop();
}
