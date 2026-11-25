import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/feedback/inline_error.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_state.dart';
import 'package:app/features/auth/presentation/widgets/code_resend_line.dart';
import 'package:app/features/auth/presentation/widgets/ltr_isolate.dart';
import 'package:app/features/auth/presentation/widgets/otp_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the code page asks: the number the code went to, the boxes, why the
/// code was refused, and the wait before a new one.
class CodeForm extends StatelessWidget {
  const CodeForm({super.key, required this.state});

  final SignInState state;

  @override
  Widget build(BuildContext context) {
    final String phone = SaudiMobile.display(state.fullPhone);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StepHeader(
          title: context.tr('auth.code_title'),
          subtitle: context.tr(
            'auth.code_sent_to',
            args: <String>[ltrIsolate(phone)],
          ),
          onBack: () => leaveCodePage(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        EditPhoneButton(onPressed: () => leaveCodePage(context)),
        const SizedBox(height: AppSpacing.lg),
        OtpField(
          length: SignInCubit.codeLength,
          value: state.code,
          hasError: state.errorKey != null,
          onChanged: context.read<SignInCubit>().codeChanged,
          // The last digit sends the code at once.
          onCompleted: (_) => context.read<SignInCubit>().verify(),
        ),
        if (state.errorKey != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          InlineError(messageKey: state.errorKey!),
        ],
        const SizedBox(height: AppSpacing.lg),
        CodeResendLine(resendSeconds: state.resendSeconds),
      ],
    );
  }
}

/// «تعديل الرقم» under the code page's title.
class EditPhoneButton extends StatelessWidget {
  const EditPhoneButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppSemanticColors.textPrimary,
        padding: EdgeInsets.zero,
        alignment: AlignmentDirectional.centerStart,
      ),
      child: Text(
        context.tr('auth.edit_phone'),
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: AppSemanticColors.textPrimary),
      ),
    );
  }
}
