import 'package:app/features/simplified_mode/domain/entities/simplified_text_size.dart';
import 'package:app/features/simplified_mode/domain/repositories/simplified_settings_store.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_settings_state.dart';
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
}
