import 'package:app/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:app/features/auth/presentation/widgets/ltr_isolate.dart';
import 'package:app/features/auth/presentation/widgets/wait_clock.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The wait before a new code, or «إعادة الإرسال» once it is over.
class CodeResendLine extends StatelessWidget {
  const CodeResendLine({super.key, required this.resendSeconds});

  final int resendSeconds;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: resendSeconds > 0
          ? Text(
              context.tr(
                'auth.resend_in',
                args: <String>[ltrIsolate(waitClock(resendSeconds))],
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            )
          : TextButton(
              onPressed: context.read<SignInCubit>().resendCode,
              child: Text(context.tr('auth.resend')),
            ),
    );
  }
}
