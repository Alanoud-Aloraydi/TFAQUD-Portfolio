import 'package:flutter/foundation.dart';
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
    // Every way speech ends puts the button back to «استماع».
    _tts
      ..setCompletionHandler(_stopped)
      ..setCancelHandler(_stopped)
      ..setErrorHandler((_) => _stopped());
  }

  final FlutterTts _tts = FlutterTts();
  late final Future<void> _ready;
  final ValueNotifier<bool> _speaking = ValueNotifier<bool>(false);

  /// Whether it is reading aloud now, so the button can offer «إيقاف».
  ValueListenable<bool> get speaking => _speaking;

  void _stopped() => _speaking.value = false;

  /// Speaks [segments] one after another, stopping whatever it was saying.
  Future<void> speak(List<String> segments) async {
    await _ready;
    await _tts.stop();
    _speaking.value = true;
    await _tts.speak(segments.where((text) => text.isNotEmpty).join('. '));
  }

  Future<void> stop() async {
    await _tts.stop();
    _stopped();
  }
}
