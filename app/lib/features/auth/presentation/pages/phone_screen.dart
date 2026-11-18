import 'package:app/core/navigation/routers.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_state.dart';
import 'package:app/features/auth/presentation/widgets/phone_form.dart';
import 'package:app/features/auth/presentation/widgets/sign_in_step_column.dart';
import 'package:app/features/auth/presentation/widgets/sign_in_step_frame.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Phone number page. Needs a [SignInCubit] above it in the widget tree.
class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Shows the number again when the user comes back from the code page.
    _controller = TextEditingController(
      text: SaudiMobile.group(context.read<SignInCubit>().state.phone),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final bool sent = await context.read<SignInCubit>().sendCode();
    if (sent && mounted) context.push(Routes.authCode);
  }

  @override
  Widget build(BuildContext context) {
    return SignInStepFrame(
      child: BlocBuilder<SignInCubit, SignInState>(
        builder: (BuildContext context, SignInState state) {
          return SignInStepColumn(
            form: PhoneForm(controller: _controller, state: state),
            button: PillButton(
              label: context.tr('auth.send_code'),
              isLoading: state.status == SignInStatus.sendingCode,
              onPressed: _send,
            ),
          );
        },
      ),
    );
  }
}
