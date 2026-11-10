import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:equatable/equatable.dart';

/// Defines the supported home status values.
enum HomeStatus { loading, ready, failure, signIn, onboarding }

/// Holds the home presentation state.
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
