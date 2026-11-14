import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:equatable/equatable.dart';

enum HomeStatus { loading, ready, failure, signIn, onboarding }

/// The day on screen and which circle it belongs to.
class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.loading,
    this.data,
    this.selectedCircleId,
    this.messageKey,
  });

  final HomeStatus status;
  final HomeEntity? data;
  final String? selectedCircleId;
  final String? messageKey;

  /// The selected circle, with its patient's zone; null while loading.
  CareCircleSummary? get selectedCircle => data?.circles
      .where((circle) => circle.id == selectedCircleId)
      .firstOrNull;

  @override
  List<Object?> get props => [status, data, selectedCircleId, messageKey];
}
