import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:injectable/injectable.dart';

/// The Arabic language among the phone's [languages], or null without one.
///
/// iOS 17 and later name its Arabic voice `ar-001`, older versions and
/// Android `ar-SA` or `ar`. A language the phone lacks is refused without an
/// error, and the phone's own voice, usually English, then reads Arabic text
/// as silence; so the name comes from the phone's list, never a fixed one.
String? arabicLanguage(Iterable<String> languages) {
  for (final String preferred in const <String>['ar-SA', 'ar-001']) {
    for (final String language in languages) {
      if (language.toLowerCase() == preferred.toLowerCase()) return language;
    }
  }
  for (final String language in languages) {
    final String code = language.toLowerCase();
    if (code == 'ar' || code.startsWith('ar-') || code.startsWith('ar_')) {
      return language;
    }
  }
  return null;
}

/// Reads text aloud for the simplified mode's «استماع» button, using the
/// phone's own Arabic voice (no network call, no API key).
@lazySingleton
class SimplifiedVoice {
  SimplifiedVoice() {
    _ready = _prepare();
    // «إيقاف» shows once the phone really speaks, and every way speech ends
    // puts the button back to «استماع». Stopping earlier speech reports its
    // end before the new speech starts, so the two never cross.
    _tts
      ..setStartHandler(() => _speaking.value = true)
      ..setCompletionHandler(_stopped)
      ..setCancelHandler(_stopped)
      ..setErrorHandler((_) => _stopped());
  }

  final FlutterTts _tts = FlutterTts();
  late final Future<void> _ready;
  final ValueNotifier<bool> _speaking = ValueNotifier<bool>(false);

  /// The phone's Arabic language, or null when it has no Arabic voice.
  String? _arabic;

  /// Whether it is reading aloud now, so the button can offer «إيقاف».
  ValueListenable<bool> get speaking => _speaking;

  void _stopped() => _speaking.value = false;

  Future<void> _prepare() async {
    final Object? languages = await _tts.getLanguages;
    _arabic = arabicLanguage(<String>[
      if (languages is List)
        for (final Object? language in languages)
          if (language is String) language,
    ]);
    final String? arabic = _arabic;
    if (arabic != null) await _tts.setLanguage(arabic);
    await _tts.setSpeechRate(0.45);
  }

  /// Speaks [segments] one after another, stopping whatever it was saying.
  /// False, saying nothing, on a phone without an Arabic voice.
  Future<bool> speak(List<String> segments) async {
    await _ready;
    if (_arabic == null) return false;
    await _tts.stop();
    // Set before every reading, not once: recording a visit sets the phone's
    // audio for the microphone, which plays speech faintly through the
    // earpiece. The playback category also keeps speech audible while the
    // silent switch is on.
    await _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      <IosTextToSpeechAudioCategoryOptions>[
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
      ],
    );
    await _tts.speak(segments.where((text) => text.isNotEmpty).join('. '));
    return true;
  }

  Future<void> stop() async {
    await _tts.stop();
    _stopped();
  }
}
