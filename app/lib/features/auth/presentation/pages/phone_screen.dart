import 'package:app/core/navigation/routers.dart';
import 'package:app/core/widgets/inline_error.dart';
import 'package:app/core/widgets/pill_button.dart';
import 'package:app/core/widgets/step_header.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_state.dart';
import 'package:app/features/auth/presentation/widgets/phone_field.dart';
import 'package:app/core/utils/arabic_digits.dart';
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
      text: PhoneNumberFormatter.display(
        context.read<SignInCubit>().state.phone,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.auth);
    }
  }

  Future<void> _send() async {
    final bool sent = await context.read<SignInCubit>().sendCode();
    if (sent && mounted) context.push(Routes.authCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: BlocBuilder<SignInCubit, SignInState>(
            builder: (BuildContext context, SignInState state) {
              return Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          StepHeader(
                            title: context.tr('auth.phone_title'),
                            subtitle: context.tr('auth.phone_subtitle'),
                            onBack: _back,
                          ),
                          const SizedBox(height: 24),
                          PhoneField(
                            controller: _controller,
                            showError: state.showPhoneError,
                            onChanged: (String text) => context
                                .read<SignInCubit>()
                                .phoneChanged(ArabicDigits.digitsOnly(text)),
                          ),
                          if (state.errorKey != null) ...<Widget>[
                            const SizedBox(height: 16),
                            InlineError(messageKey: state.errorKey!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PillButton(
                    label: context.tr('auth.send_code'),
                    isLoading: state.status == SignInStatus.sendingCode,
                    onPressed: _send,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
