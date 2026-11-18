import 'package:app/features/account/domain/use_cases/profile_use_case.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the onboarding steps are bound to, shared by everything they do.
mixin OnboardingScope on Cubit<OnboardingState> {
  ProfileUseCase get profile;
}
