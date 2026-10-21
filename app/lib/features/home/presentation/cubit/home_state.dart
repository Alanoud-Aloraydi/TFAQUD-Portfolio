import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:equatable/equatable.dart';

enum HomeStatus { loading, ready, failure, signIn, onboarding }

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

  @override
  List<Object?> get props => [status, data, selectedCircleId, messageKey];
}
