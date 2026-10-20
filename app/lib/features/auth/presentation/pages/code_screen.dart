import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/widgets/inline_error.dart';
import 'package:app/core/widgets/pill_button.dart';
import 'package:app/core/widgets/step_header.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_state.dart';
import 'package:app/features/auth/presentation/widgets/otp_field.dart';
import 'package:app/features/auth/presentation/widgets/phone_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Code page. Needs the same [SignInCubit] as the phone page above it.
class CodeScreen extends StatelessWidget {
  const CodeScreen({super.key});

  // U+2066 and U+2069 keep a number written left to right inside Arabic text.
  static String _isolate(String text) => '\u2066$text\u2069';

  static String _clock(int seconds) {
    final String minutes = (seconds ~/ 60).toString();
    final String rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }

  void _back(BuildContext context) {
    context.read<SignInCubit>().backToPhone();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.authPhone);
    }
  }

  Future<void> _confirm(BuildContext context) async {
    final SignInCubit cubit = context.read<SignInCubit>();
    final bool correct = await cubit.verify();
    if (!context.mounted || !correct) return;
    // A user who has not saved the name page goes to it; the others go home.
    context.go(cubit.state.needsProfile ? Routes.onboarding : Routes.today);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: BlocBuilder<SignInCubit, SignInState>(
            builder: (BuildContext context, SignInState state) {
              final String phone =
                  '+966 ${PhoneNumberFormatter.display(state.phone)}';
              return Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          StepHeader(
                            title: context.tr('auth.code_title'),
                            subtitle: context.tr(
                              'auth.code_sent_to',
                              args: <String>[_isolate(phone)],
                            ),
                            onBack: () => _back(context),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _back(context),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.brand,
                              padding: EdgeInsets.zero,
                              alignment: AlignmentDirectional.centerStart,
                            ),
                            child: Text(
                              context.tr('auth.edit_phone'),
                              style: text.labelLarge?.copyWith(
                                color: AppColors.brand,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          OtpField(
                            length: SignInCubit.codeLength,
                            value: state.code,
                            hasError: state.errorKey != null,
                            onChanged: context.read<SignInCubit>().codeChanged,
                          ),
                          if (state.errorKey != null) ...<Widget>[
                            const SizedBox(height: 16),
                            InlineError(messageKey: state.errorKey!),
                          ],
                          const SizedBox(height: 16),
                          Center(
                            child: state.resendSeconds > 0
                                ? Text(
                                    context.tr(
                                      'auth.resend_in',
                                      args: <String>[
                                        _isolate(_clock(state.resendSeconds)),
                                      ],
                                    ),
                                    style: text.bodyMedium,
                                  )
                                : TextButton(
                                    onPressed: context
                                        .read<SignInCubit>()
                                        .resendCode,
                                    child: Text(context.tr('auth.resend')),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PillButton(
                    label: context.tr('auth.confirm'),
                    isLoading: state.status == SignInStatus.verifying,
                    onPressed: () => _confirm(context),
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
