import 'package:app/features/simplified_mode/data/simplified_preferences.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_text_size.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The simplified mode's display settings on this phone.
class SimplifiedSettingsState extends Equatable {
  const SimplifiedSettingsState({
    this.textSize = SimplifiedTextSize.normal,
    this.voiceEnabled = true,
  });

  final SimplifiedTextSize textSize;

  /// Whether «استماع» shows on the screens.
  final bool voiceEnabled;

  @override
  List<Object?> get props => [textSize, voiceEnabled];
}

/// Reads and changes the text size and «استماع». A change shows at once on
/// every simplified screen, and is kept for the next start.
class SimplifiedSettingsCubit extends Cubit<SimplifiedSettingsState> {
  SimplifiedSettingsCubit(this._preferences)
    : super(const SimplifiedSettingsState());

  final SimplifiedPreferences _preferences;

  Future<void> load() async {
    final (textSize, voiceEnabled) = await (
      _preferences.textSize(),
      _preferences.voiceEnabled(),
    ).wait;
    if (isClosed) return;
    emit(
      SimplifiedSettingsState(textSize: textSize, voiceEnabled: voiceEnabled),
    );
  }

  Future<void> setTextSize(SimplifiedTextSize value) async {
    emit(
      SimplifiedSettingsState(
        textSize: value,
        voiceEnabled: state.voiceEnabled,
      ),
    );
    await _preferences.saveTextSize(value);
  }

  Future<void> setVoiceEnabled(bool value) async {
    emit(
      SimplifiedSettingsState(textSize: state.textSize, voiceEnabled: value),
    );
    await _preferences.saveVoiceEnabled(value);
  }
}
