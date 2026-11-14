import 'dart:typed_data';

/// Recording and playing back the voice note of a visit, on the phone.
///
/// The screen asks for it through this; whether it is the microphone, a
/// file, or something else is the data layer's business.
abstract class VisitAudio {
  /// Starts recording. False when the microphone was refused.
  Future<bool> start();

  /// Stops recording and gives what was recorded, if anything.
  Future<Uint8List?> stop();

  /// Stops recording and keeps nothing.
  Future<void> cancel();

  /// Makes [bytes] ready to play and gives how long they run.
  Future<Duration?> prepare(Uint8List bytes);

  Future<void> play();

  Future<void> stopPlayback();

  Future<void> dispose();
}
