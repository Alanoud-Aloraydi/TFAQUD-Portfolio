import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_cubit.dart';

class OnboardingFeatureScreen extends StatelessWidget {
  const OnboardingFeatureScreen({super.key});
  @override
  Widget build(BuildContext context) {
      final _ = context.read<OnboardingCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding Feature Screen')),
      body: Column(children: [
          
        ],
      ),
    );
  }
}
