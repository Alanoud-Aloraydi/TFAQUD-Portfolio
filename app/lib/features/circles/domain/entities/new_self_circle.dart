import 'package:equatable/equatable.dart';

/// What the user chose to create a circle for their own care. The patient's
/// names are not here: the API takes them from the account. The birth date
/// and city are the account's when onboarding saved them, and are sent
/// anyway, so the zone the app picks follows the same city.
class NewSelfCircle extends Equatable {
  const NewSelfCircle({
    required this.name,
    required this.birthDate,
    required this.city,
  });

  /// The name the circle shows in the list of circles.
  final String name;
  final DateTime birthDate;
  final String city;

  @override
  List<Object?> get props => [name, birthDate, city];
}
