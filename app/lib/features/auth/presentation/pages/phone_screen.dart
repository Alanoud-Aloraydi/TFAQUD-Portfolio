import 'package:app/app/router/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/feedback/inline_error.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_cubit.dart';
import 'package:app/features/auth/presentation/cubit/sign_in_state.dart';
import 'package:app/features/auth/presentation/widgets/otp_field.dart';
import 'package:app/features/auth/presentation/widgets/phone_form.dart';
import 'package:app/features/circles/domain/entities/circle_app_mode.dart';
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

/// [seconds] as minutes and seconds, such as 1:05.
String waitClock(int seconds) {
  final String minutes = (seconds ~/ 60).toString();
  final String rest = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$rest';
}

/// Back from the code page to the phone number.
void leaveCodePage(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    // Opened directly (a reload on the web): there is no page to return to.
    context.read<SignInCubit>().backToPhone();
    context.go(Routes.authPhone);
  }
}

/// Where a verified sign-in goes: a user who has not saved the name page
/// goes to it; the others go home, to whichever home their account's app
/// mode uses.
void goSignedIn(BuildContext context, SignInState state) {
  context.go(
    state.needsProfile
        ? Routes.onboarding
        : state.appMode == CircleAppMode.simplified
        ? Routes.simplifiedMode
        : Routes.today,
  );
}

/// [text] kept left to right inside Arabic text: U+2066 and U+2069 isolate
/// a number written left to right.
String ltrIsolate(String text) => '\u2066$text\u2069';
