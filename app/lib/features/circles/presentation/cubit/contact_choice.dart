import 'package:app/features/circles/presentation/cubit/contact_form.dart';
import 'package:equatable/equatable.dart';

/// A circle member who can be picked as an emergency contact: their name,
/// number and picture fill the form.
class ContactChoice extends Equatable {
  const ContactChoice({
    required this.name,
    required this.phone,
    this.accountId,
    this.avatarCode,
  });

  final String name;

  /// The nine digits without the country code, as [ContactForm.phone].
  final String phone;
  final String? accountId;
  final String? avatarCode;

  @override
  List<Object?> get props => [name, phone, accountId, avatarCode];
}
