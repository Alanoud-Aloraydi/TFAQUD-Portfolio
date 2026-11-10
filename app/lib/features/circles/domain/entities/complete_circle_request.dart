import 'package:equatable/equatable.dart';

/// What the patient sends after agreeing to a request (PROFILE-01C). The
/// patient's name comes from the account. The birth date and city are the
/// account's when onboarding saved them, sent anyway like a circle of the
/// person's own care. Sending this creates the circle.
class CompleteCircleRequest extends Equatable {
  const CompleteCircleRequest({
    required this.name,
    required this.birthDate,
    required this.city,
  });

  /// The patient's own name for the circle («رعايتي», «صحتي»...). Only they
  /// see it; the others see «دائرة» and the patient's name.
  final String name;
  final DateTime birthDate;
  final String city;

  @override
  List<Object?> get props => [name, birthDate, city];
}
