import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_state.dart';
import 'package:app/features/auth/presentation/widgets/code_form.dart';
import 'package:app/features/auth/presentation/widgets/code_routes.dart';
import 'package:app/features/auth/presentation/widgets/sign_in_step_column.dart';
import 'package:app/features/auth/presentation/widgets/sign_in_step_frame.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Code page. Needs the same [SignInCubit] as the phone page above it.
class CodeScreen extends StatelessWidget {
  const CodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The system back gesture also leaves the number: the request goes.
    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) context.read<SignInCubit>().backToPhone();
      },
      child: SignInStepFrame(
        child: BlocConsumer<SignInCubit, SignInState>(
          listenWhen: (SignInState before, SignInState after) =>
              before.status != SignInStatus.verified &&
              after.status == SignInStatus.verified,
          listener: goSignedIn,
          builder: (BuildContext context, SignInState state) {
            return SignInStepColumn(
              form: CodeForm(state: state),
              button: PillButton(
                label: context.tr('auth.confirm'),
                isLoading:
                    state.status == SignInStatus.verifying ||
                    state.status == SignInStatus.verified,
                onPressed: context.read<SignInCubit>().verify,
              ),
            );
          },
        ),
      ),
    );
  }
}
