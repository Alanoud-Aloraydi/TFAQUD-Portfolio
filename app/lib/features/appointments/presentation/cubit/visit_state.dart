import 'package:app/features/appointments/domain/visit_paper.dart';
import 'package:equatable/equatable.dart';

/// What the visit page shows, including the recording in progress.
class VisitState extends Equatable {
  const VisitState({
    this.loading = true,
    this.loadFailed = false,
    this.saving = false,
    this.recording = false,
    this.playing = false,
    this.recordedSeconds = 0,
    this.audioSeconds,
    this.paper,
    this.errorKey,
  });

  final bool loading;

  /// The visit could not be read; the page offers a retry.
  final bool loadFailed;
  final bool saving;
  final bool recording;
  final bool playing;
  final int recordedSeconds;
  final int? audioSeconds;
  final VisitPaper? paper;
  final String? errorKey;

  VisitState copyWith({
    bool? loading,
    bool? loadFailed,
    bool? saving,
    bool? recording,
    bool? playing,
    int? recordedSeconds,
    int? audioSeconds,
    VisitPaper? paper,
    bool replacePaper = false,
    String? errorKey,
    bool clearError = false,
  }) => VisitState(
    loading: loading ?? this.loading,
    loadFailed: loadFailed ?? this.loadFailed,
    saving: saving ?? this.saving,
    recording: recording ?? this.recording,
    playing: playing ?? this.playing,
    recordedSeconds: recordedSeconds ?? this.recordedSeconds,
    audioSeconds: audioSeconds ?? this.audioSeconds,
    paper: replacePaper ? paper : this.paper,
    errorKey: clearError ? null : errorKey ?? this.errorKey,
  );

  @override
  List<Object?> get props => [
    loading,
    loadFailed,
    saving,
    recording,
    playing,
    recordedSeconds,
    audioSeconds,
    paper,
    errorKey,
  ];
}

/// The longest recording; the server keeps 5 MB, this is far below it.
const int maxRecordingSeconds = 300;
