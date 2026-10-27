import 'package:app/core/navigation/routers.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';

/// The pages after the first one are the same for every [CircleFlow], but each
/// flow has its own addresses. This tells a page where the next one is.
extension CircleFlowRoutes on CircleFlow {
  String get healthRoute => switch (this) {
    CircleFlow.self => Routes.createSelfCircleHealth,
    CircleFlow.patient => Routes.createPatientCircleHealth,
    CircleFlow.approved => Routes.completeRequestHealth,
  };

  String get allergiesRoute => switch (this) {
    CircleFlow.self => Routes.createSelfCircleAllergies,
    CircleFlow.patient => Routes.createPatientCircleAllergies,
    CircleFlow.approved => Routes.completeRequestAllergies,
  };
}
