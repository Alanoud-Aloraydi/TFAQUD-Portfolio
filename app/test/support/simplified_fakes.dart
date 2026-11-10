import 'package:app/features/simplified_mode/data/simplified_voice.dart';
import 'package:flutter/foundation.dart';

/// The simplified mode's voice, kept in memory: what it was told to say and
/// how often it was stopped.
class FakeSimplifiedVoice implements SimplifiedVoice {
  final List<(List<SpokenPart>, double)> said = <(List<SpokenPart>, double)>[];
  int stops = 0;

  @override
  final ValueNotifier<bool> speaking = ValueNotifier<bool>(false);

  @override
  final ValueNotifier<Object?> reading = ValueNotifier<Object?>(null);

  @override
  Future<bool> speak(List<SpokenPart> parts, {required double rate}) async {
    said.add((parts, rate));
    return true;
  }

  @override
  Future<void> stop() async => stops++;
}
