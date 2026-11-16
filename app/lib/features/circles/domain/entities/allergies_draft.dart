import 'package:app/features/circles/domain/entities/list_answer.dart';
import 'package:equatable/equatable.dart';

/// The allergies the user chose.
class AllergiesDraft extends Equatable {
  const AllergiesDraft.none()
    : answer = ListAnswer.none,
      medication = const <String>[],
      otherMedication = null,
      food = const <String>[],
      otherFood = null;

  const AllergiesDraft.listed({
    this.medication = const <String>[],
    this.otherMedication,
    this.food = const <String>[],
    this.otherFood,
  }) : answer = ListAnswer.listed;

  final ListAnswer answer;
  final List<String> medication;
  final String? otherMedication;
  final List<String> food;
  final String? otherFood;

  @override
  List<Object?> get props => [
    answer,
    medication,
    otherMedication,
    food,
    otherFood,
  ];
}
