import 'package:equatable/equatable.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

class OnboardingInitialState extends OnboardingState {}
class OnboardingSuccessState extends OnboardingState {}

class OnboardingErrorState extends OnboardingState {
  final String message;
  const OnboardingErrorState({required this.message});
  @override
  List<Object?> get props => [message];
}

