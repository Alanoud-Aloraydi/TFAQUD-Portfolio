import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/complete_circle_request.dart';
import 'package:app/features/circles/domain/entities/new_patient_circle.dart';
import 'package:app/features/circles/domain/entities/new_self_circle.dart';
import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/circle_flow.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:multiple_result/multiple_result.dart';

/// Creates the circle of [flow] with the answers in [state], and says which
/// mode the account is left in.
Future<Result<(CareCircleSummary, CircleAppMode), Failure>> createCircleCall(
  CirclesUseCase circles, {
  required CircleFlow flow,
  required CreateCircleState state,
  required String name,
  required DateTime birthDate,
  required String city,
  required ReceivedCircleRequest? request,
}) async => switch (flow) {
  CircleFlow.self => _detailed(
    await circles.createSelfCircle(
      NewSelfCircle(name: name, birthDate: birthDate, city: city),
    ),
  ),
  CircleFlow.patient => _detailed(
    await circles.createPatientCircle(
      NewPatientCircle(
        patientFirstName: state.patientFirstName.trim(),
        patientLastName: state.patientLastName.trim(),
        birthDate: birthDate,
        city: city,
      ),
    ),
  ),
  CircleFlow.approved => await circles.completeRequest(
    request!.id,
    CompleteCircleRequest(name: name, birthDate: birthDate, city: city),
  ),
};

/// A circle the person creates for themself or for a patient without the
/// app leaves the account in the detailed mode (the server commits it).
Result<(CareCircleSummary, CircleAppMode), Failure> _detailed(
  Result<CareCircleSummary, Failure> result,
) => result.when(
  (circle) => Success((circle, CircleAppMode.detailed)),
  (failure) => Error(failure),
);
