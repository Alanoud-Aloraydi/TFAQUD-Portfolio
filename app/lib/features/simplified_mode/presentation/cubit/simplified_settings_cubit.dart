import 'package:app/features/simplified_mode/domain/entities/simplified_reading.dart';
import 'package:app/features/simplified_mode/domain/repositories/simplified_settings_store.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reads and changes the text size. A change shows at once on every
/// simplified screen, and is kept for the next start.
class SimplifiedSettingsCubit extends Cubit<SimplifiedSettingsState> {
  SimplifiedSettingsCubit(this._preferences)
    : super(const SimplifiedSettingsState());

  final SimplifiedSettingsStore _preferences;

  Future<void> load() async {
    final SimplifiedTextSize textSize = await _preferences.textSize();
    if (isClosed) return;
    emit(SimplifiedSettingsState(textSize: textSize, loaded: true));
  }

  Future<void> setTextSize(SimplifiedTextSize value) async {
    emit(state.copyWith(textSize: value));
    await _preferences.saveTextSize(value);
  }
}

/// The simplified mode's display settings on this phone.
class SimplifiedSettingsState extends Equatable {
  const SimplifiedSettingsState({
    this.textSize = SimplifiedTextSize.normal,
    this.loaded = false,
  });

  final SimplifiedTextSize textSize;

  /// Whether the saved settings have been read; until then the value is the
  /// default, which a screen opened at the app's start must not take for
  /// the person's choice.
  final bool loaded;

  SimplifiedSettingsState copyWith({SimplifiedTextSize? textSize}) {
    return SimplifiedSettingsState(
      textSize: textSize ?? this.textSize,
      loaded: loaded,
    );
  }

  @override
  List<Object?> get props => [textSize, loaded];
}
