import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/features/circles/domain/medical_options.dart';
import 'package:app/features/circles/presentation/cubit/contact_form.dart';

/// What [ContactForm] needs before it can be saved.
extension ContactFormChecks on ContactForm {
  /// A relation is picked, and «أخرى» has its words.
  bool get relationAnswered =>
      relation != null &&
      (relation != MedicalOptions.other || relationOther.trim().isNotEmpty);

  /// The words of «أخرى» are missing after a tap on «حفظ».
  bool get relationOtherMissing =>
      showErrors && relation == MedicalOptions.other && !relationAnswered;

  /// A whole Saudi mobile number: emergency contacts are Saudi numbers.
  bool get phoneValid => SaudiMobile.isValid(phone);
}
