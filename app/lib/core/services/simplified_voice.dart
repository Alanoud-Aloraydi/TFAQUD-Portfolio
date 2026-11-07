import 'package:flutter_tts/flutter_tts.dart';
import 'package:injectable/injectable.dart';

/// Reads text aloud for the simplified mode's «استماع» button, using the
/// phone's own Arabic voice (no network call, no API key).
@lazySingleton
class SimplifiedVoice {
  SimplifiedVoice() {
    _ready = _tts
        .setLanguage('ar-SA')
        .then((_) => _tts.setSpeechRate(0.45))
        // Without this, iOS plays nothing at all while the silent switch is
        // on — the default category follows it like any other media sound.
        .then(
          (_) => _tts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            <IosTextToSpeechAudioCategoryOptions>[
              IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            ],
          ),
        );
  }

  final FlutterTts _tts = FlutterTts();
  late final Future<void> _ready;

  /// Speaks [segments] one after another, stopping whatever it was saying.
  Future<void> speak(List<String> segments) async {
    await _ready;
    await _tts.stop();
    await _tts.speak(segments.where((text) => text.isNotEmpty).join('. '));
  }

  Future<void> stop() => _tts.stop();
}
