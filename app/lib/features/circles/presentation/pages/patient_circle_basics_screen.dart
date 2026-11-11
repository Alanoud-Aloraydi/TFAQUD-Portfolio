import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/features/circles/presentation/circle_creation_finish.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/widgets/patient_basics_form.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The circle for a person without the app (PROFILE-01B), named for all
/// «دائرة» and the first name. Needs a [CreateCircleCubit] above it.
class PatientCircleBasicsScreen extends StatefulWidget {
  const PatientCircleBasicsScreen({super.key});

  @override
  State<PatientCircleBasicsScreen> createState() => _PatientBasicsState();
}

class _PatientBasicsState extends State<PatientCircleBasicsScreen> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;

  @override
  void initState() {
    super.initState();
    final CreateCircleState state = context.read<CreateCircleCubit>().state;
    _firstName = TextEditingController(text: state.patientFirstName);
    _lastName = TextEditingController(text: state.patientLastName);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CreateCircleCubit cubit = context.read<CreateCircleCubit>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: BlocBuilder<CreateCircleCubit, CreateCircleState>(
            builder: (BuildContext context, CreateCircleState state) => Column(
              children: <Widget>[
                Expanded(
                  child: PatientBasicsForm(
                    state: state,
                    cubit: cubit,
                    firstName: _firstName,
                    lastName: _lastName,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                PillButton(
                  label: context.tr('circles.create'),
                  isLoading: state.busy,
                  onPressed: () => createCircleAndOpen(context, cubit),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
