import 'package:app/features/simplified_mode/domain/entities/simplified_text_size.dart';
import 'package:equatable/equatable.dart';

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
