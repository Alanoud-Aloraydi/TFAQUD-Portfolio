import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:injectable/injectable.dart';

/// One part of a screen read aloud: [text] as it should sound, and [id],
/// the part of the screen that shows it (null for one that is not marked).
typedef SpokenPart = ({Object? id, String text});

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
    if (_isArabic(language)) return language;
  }
  return null;
}

/// The clearest Arabic voice among the phone's [voices] (each as the speech
/// plugin lists it: `name`, `locale`, `quality`, `identifier`), or null
/// without one. A premium or enhanced voice, which the person may have
/// downloaded, reads far more naturally than the default compact one.
Map<String, String>? bestArabicVoice(Iterable<Map<String, String>> voices) {
  const List<String> qualities = <String>['premium', 'enhanced'];
  Map<String, String>? best;
  int bestRank = qualities.length;
  for (final Map<String, String> voice in voices) {
    if (!_isArabic(voice['locale'] ?? '')) continue;
    final int found = qualities.indexOf(voice['quality'] ?? '');
    final int rank = found == -1 ? qualities.length : found;
    if (best == null || rank < bestRank) {
      best = voice;
      bestRank = rank;
    }
  }
  return best;
}

bool _isArabic(String language) {
  final String code = language.toLowerCase();
  return code == 'ar' || code.startsWith('ar-') || code.startsWith('ar_');
}

/// Reads a screen aloud for the simplified mode's «استماع» button, using the
/// phone's own Arabic voice (no network call, no API key), and tells which
/// part it is reading so the screen can mark it.
@lazySingleton
class SimplifiedVoice {
  SimplifiedVoice() {
    _ready = _prepare();
    // «إيقاف» shows once the phone really speaks, and every way speech ends
    // puts the button back to «استماع». Stopping earlier speech reports its
    // end before the new speech starts, so the two never cross.
    _tts
      ..setStartHandler(_started)
      ..setProgressHandler(_progressed)
      ..setCompletionHandler(_stopped)
      ..setCancelHandler(_stopped)
      ..setErrorHandler((_) => _stopped());
  }

  final FlutterTts _tts = FlutterTts();
  late final Future<void> _ready;
  final ValueNotifier<bool> _speaking = ValueNotifier<bool>(false);
  final ValueNotifier<Object?> _reading = ValueNotifier<Object?>(null);

  /// Whether the phone has an Arabic voice; known once [_ready] completes.
  bool _hasArabic = false;

  /// Where each part starts in the text being read, in order.
  List<(int, Object?)> _starts = const <(int, Object?)>[];

  /// Whether it is reading aloud now, so the button can offer «إيقاف».
  ValueListenable<bool> get speaking => _speaking;

  /// The [SpokenPart.id] of the part being read, or null.
  ValueListenable<Object?> get reading => _reading;

  void _started() {
    _speaking.value = true;
    if (_starts.isNotEmpty) _reading.value = _starts.first.$2;
  }

  void _progressed(String text, int start, int end, String word) {
    _reading.value = partAt(_starts, start);
  }

  void _stopped() {
    _speaking.value = false;
    _reading.value = null;
  }

  Future<void> _prepare() async {
    final Object? voices = await _tts.getVoices;
    final Map<String, String>? voice = bestArabicVoice(<Map<String, String>>[
      if (voices is List)
        for (final Object? entry in voices)
          if (entry is Map)
            <String, String>{
              for (final MapEntry<Object?, Object?> field in entry.entries)
                if (field.key is String && field.value is String)
                  field.key! as String: field.value! as String,
            },
    ]);
    if (voice != null) {
      _hasArabic = true;
      await _tts.setVoice(voice);
    } else {
      // Some phones list languages but no voices; the language still
      // speaks with the phone's default voice for it.
      final Object? languages = await _tts.getLanguages;
      final String? arabic = arabicLanguage(<String>[
        if (languages is List)
          for (final Object? language in languages)
            if (language is String) language,
      ]);
      if (arabic != null) {
        _hasArabic = true;
        await _tts.setLanguage(arabic);
      }
    }
  }

  /// Reads [parts] one after another as one speech at [rate] (the speech
  /// plugin's, 0.5 being the phone's own pace on iOS), stopping whatever it
  /// was saying, and marks each part in [reading] as it reaches it. False,
  /// saying nothing, on a phone without an Arabic voice.
  Future<bool> speak(List<SpokenPart> parts, {required double rate}) async {
    await _ready;
    if (!_hasArabic) return false;
    await _tts.stop();
    final (String text, List<(int, Object?)> starts) = joinParts(parts);
    if (text.isEmpty) return true;
    _starts = starts;
    // Set before every reading, so a pace chosen in «حسابي» is heard at
    // the next one.
    await _tts.setSpeechRate(rate);
    // Also set before every reading: recording a visit sets the phone's
    // audio for the microphone, which plays speech faintly through the
    // earpiece. The playback category also keeps speech audible while the
    // silent switch is on.
    await _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      <IosTextToSpeechAudioCategoryOptions>[
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
      ],
    );
    await _tts.speak(text);
    return true;
  }

  Future<void> stop() async {
    await _tts.stop();
    _stopped();
  }
}

/// [parts] as one text, each ending in a full stop so the voice pauses
/// between them, with where each one starts. Empty parts are left out.
(String, List<(int, Object?)>) joinParts(List<SpokenPart> parts) {
  final StringBuffer text = StringBuffer();
  final List<(int, Object?)> starts = <(int, Object?)>[];
  for (final SpokenPart part in parts) {
    final String words = part.text.trim();
    if (words.isEmpty) continue;
    if (text.isNotEmpty) text.write(' ');
    starts.add((text.length, part.id));
    text.write(words);
    if (!words.endsWith('.') && !words.endsWith('؟') && !words.endsWith('!')) {
      text.write('.');
    }
  }
  return (text.toString(), starts);
}

/// The id of the part that [offset] (a character of the joined text) falls
/// in, given where each part starts.
Object? partAt(List<(int, Object?)> starts, int offset) {
  Object? id;
  for (final (int start, Object? part) in starts) {
    if (start > offset) break;
    id = part;
  }
  return id;
}
