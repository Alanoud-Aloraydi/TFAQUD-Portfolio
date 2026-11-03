import 'dart:io';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

class VisitAudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  File? _playbackFile;

  Future<bool> start() async {
    if (!await _recorder.hasPermission()) return false;
    final path =
        '${Directory.systemTemp.path}/'
        'tafaqod-visit-${DateTime.now().microsecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
      path: path,
    );
    return true;
  }

  Future<Uint8List?> stop() async {
    final path = await _recorder.stop();
    if (path == null) return null;
    final file = File(path);
    try {
      return await file.readAsBytes();
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> cancel() => _recorder.cancel();

  Future<Duration?> prepare(Uint8List bytes) async {
    await _player.stop();
    await _clearPlaybackFile();
    final file = File(
      '${Directory.systemTemp.path}/'
      'tafaqod-play-${DateTime.now().microsecondsSinceEpoch}.m4a',
    );
    await file.writeAsBytes(bytes, flush: true);
    _playbackFile = file;
    return _player.setFilePath(file.path);
  }

  Future<void> play() => _player.play();

  Future<void> stopPlayback() => _player.stop();

  Future<void> dispose() async {
    await _recorder.dispose();
    await _player.dispose();
    await _clearPlaybackFile();
  }

  Future<void> _clearPlaybackFile() async {
    final file = _playbackFile;
    _playbackFile = null;
    if (file != null && await file.exists()) await file.delete();
  }
}
