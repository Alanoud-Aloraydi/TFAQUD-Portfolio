import 'package:app/features/simplified_mode/domain/entities/simplified_text_size.dart';

/// The simplified mode's own settings, kept on this phone: they belong to
/// the device, not to the account.
abstract class SimplifiedSettingsStore {
  Future<SimplifiedTextSize> textSize();

  Future<void> saveTextSize(SimplifiedTextSize size);
}
