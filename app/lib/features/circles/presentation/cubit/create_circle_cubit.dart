import 'package:app/features/circles/domain/entities/received_circle_request.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_account.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_answers.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_creating.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_result.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_scope.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/home/domain/use_cases/home_use_case.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'package:app/features/circles/presentation/cubit/create_circle_scope.dart'
    show maxCustomNameLength;

/// Keeps the answers of the page that creates a circle and creates the circle
/// of its [flow].
class CreateCircleCubit extends Cubit<CreateCircleState>
    with
        CreateCircleScope,
        CreateCircleAccount,
        CreateCircleAnswers,
        CreateCircleResult,
        CreateCircleCreating {
  /// [request] is the request the patient agreed to, and is needed for the
  /// [CircleFlow.approved] flow only; it travels with the route. The patient
  /// names that circle on the page, as they would their own.
  CreateCircleCubit(this.circles, this.home, {required this.flow, this.request})
    : super(
        CreateCircleState(
          accountLoad: flow == CircleFlow.patient
              ? AccountLoad.notNeeded
              : AccountLoad.loading,
        ),
      );

  @override
  final CirclesUseCase circles;

  @override
  final HomeUseCase home;

  @override
  final CircleFlow flow;

  @override
  final ReceivedCircleRequest? request;
}
