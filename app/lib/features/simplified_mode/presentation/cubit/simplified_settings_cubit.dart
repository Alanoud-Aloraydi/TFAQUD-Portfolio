import 'package:app/features/simplified_mode/data/simplified_preferences.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_speech_rate.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_text_size.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The simplified mode's display and reading settings on this phone.
class SimplifiedSettingsState extends Equatable {
  const SimplifiedSettingsState({
    this.textSize = SimplifiedTextSize.normal,
    this.voiceEnabled = true,
    this.speechRate = SimplifiedSpeechRate.normal,
    this.autoRead = true,
    this.loaded = false,
  });

  final SimplifiedTextSize textSize;

  /// Whether «استماع» and the cards' speakers show on the screens.
  final bool voiceEnabled;

  /// How fast they read.
  final SimplifiedSpeechRate speechRate;

  /// Whether a full-screen reminder reads itself once it opens.
  final bool autoRead;

  /// Whether the saved settings have been read; until then the values are
  /// the defaults, which a reminder opened at the app's start must not
  /// take for the person's choice.
  final bool loaded;

  SimplifiedSettingsState copyWith({
    SimplifiedTextSize? textSize,
    bool? voiceEnabled,
    SimplifiedSpeechRate? speechRate,
    bool? autoRead,
  }) {
    return SimplifiedSettingsState(
      textSize: textSize ?? this.textSize,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      speechRate: speechRate ?? this.speechRate,
      autoRead: autoRead ?? this.autoRead,
      loaded: loaded,
    );
  }

  @override
  List<Object?> get props => [
    textSize,
    voiceEnabled,
    speechRate,
    autoRead,
    loaded,
  ];
}

/// Reads and changes the text size and reading settings. A change shows at
/// once on every simplified screen, and is kept for the next start.
class SimplifiedSettingsCubit extends Cubit<SimplifiedSettingsState> {
  SimplifiedSettingsCubit(this._preferences)
    : super(const SimplifiedSettingsState());

  final SimplifiedPreferences _preferences;

  Future<void> load() async {
    final (textSize, voiceEnabled, speechRate, autoRead) = await (
      _preferences.textSize(),
      _preferences.voiceEnabled(),
      _preferences.speechRate(),
      _preferences.autoRead(),
    ).wait;
    if (isClosed) return;
    emit(
      SimplifiedSettingsState(
        textSize: textSize,
        voiceEnabled: voiceEnabled,
        speechRate: speechRate,
        autoRead: autoRead,
        loaded: true,
      ),
    );
  }

  /// The settings once they are read: at once after [load], else when it
  /// ends.
  Future<SimplifiedSettingsState> whenLoaded() async {
    if (state.loaded) return state;
    return stream.firstWhere((settings) => settings.loaded);
  }

  Future<void> setTextSize(SimplifiedTextSize value) async {
    emit(state.copyWith(textSize: value));
    await _preferences.saveTextSize(value);
  }

  Future<void> setVoiceEnabled(bool value) async {
    emit(state.copyWith(voiceEnabled: value));
    await _preferences.saveVoiceEnabled(value);
  }

  Future<void> setSpeechRate(SimplifiedSpeechRate value) async {
    emit(state.copyWith(speechRate: value));
    await _preferences.saveSpeechRate(value);
  }

  Future<void> setAutoRead(bool value) async {
    emit(state.copyWith(autoRead: value));
    await _preferences.saveAutoRead(value);
  }
}
