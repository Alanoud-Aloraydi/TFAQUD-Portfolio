import 'package:app/app/router/routers.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/feedback/error_toast.dart';
import 'package:app/core/widgets/forms/choice_card.dart';
import 'package:app/core/widgets/forms/phone_field.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/features/circles/domain/entities/circle_app_mode.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_cubit.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_state.dart';
import 'package:app/features/circles/presentation/widgets/request_sent_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The page that asks a patient who uses the app for a circle (CREAT-04): the
/// patient's phone number and the mode proposed for the patient's app, as
/// two cards that each say what the mode means. The circle is not named
/// here: the patient names it for themself, and the sender sees «دائرة» and
/// the patient's name. Once the request is sent, the same page shows the
/// waiting state (CREAT-05). Needs a [SendCircleRequestCubit] above it.
class RequestPatientScreen extends StatefulWidget {
  const RequestPatientScreen({super.key});

  @override
  State<RequestPatientScreen> createState() => _RequestPatientScreenState();
}

class _RequestPatientScreenState extends State<RequestPatientScreen> {
  final TextEditingController _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: BlocConsumer<SendCircleRequestCubit, SendCircleRequestState>(
            listenWhen: (
              SendCircleRequestState before,
              SendCircleRequestState after,
            ) => after.sessionEnded && !before.sessionEnded,
            listener: (BuildContext context, SendCircleRequestState state) =>
                context.go(Routes.auth),
            builder: (BuildContext context, SendCircleRequestState state) {
              final sent = state.sent;
              if (sent != null) return RequestSentView(request: sent);
              return RequestPatientForm(phone: _phone, state: state);
            },
          ),
        ),
      ),
    );
  }
}

/// The request before it is sent: the patient's number, the proposed mode
/// and the notice, scrolling, over «إرسال الطلب» at the bottom.
class RequestPatientForm extends StatelessWidget {
  const RequestPatientForm({
    super.key,
    required this.phone,
    required this.state,
  });

  /// The typed number, kept by the page so it outlives a rebuild.
  final TextEditingController phone;
  final SendCircleRequestState state;

  @override
  Widget build(BuildContext context) {
    final SendCircleRequestCubit cubit = context.read<SendCircleRequestCubit>();
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: RequestPatientFields(phone: phone, state: state),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PillButton(
          label: context.tr('circles.send_request'),
          isLoading: state.status == SendStatus.sending,
          onPressed: () => cubit.send(),
        ),
      ],
    );
  }
}

/// The fields of the request: header, the patient's number, the proposed mode
/// and the notice.
class RequestPatientFields extends StatelessWidget {
  const RequestPatientFields({
    super.key,
    required this.phone,
    required this.state,
  });

  final TextEditingController phone;
  final SendCircleRequestState state;

  @override
  Widget build(BuildContext context) {
    final SendCircleRequestCubit cubit = context.read<SendCircleRequestCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StepHeader(
          title: context.tr('circles.request_title'),
          onBack: context.canPop() ? () => context.pop() : null,
        ),
        const SizedBox(height: AppSpacing.xl),
        RequestPatientPhone(controller: phone, state: state, cubit: cubit),
        const SizedBox(height: AppSpacing.xl),
        RequestModeChoices(mode: state.mode, onChoose: cubit.chooseMode),
        const SizedBox(height: AppSpacing.xl),
        RequestPatientNotice(text: context.tr('circles.request_notice')),
      ],
    );
  }
}

/// The yellow note above the send button: the patient is asked, and nothing is
/// created without the patient's agreement. The icon keeps the colour from being
/// the only signal.
class RequestPatientNotice extends StatelessWidget {
  const RequestPatientNotice({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.inset),
      decoration: BoxDecoration(
        color: AppSemanticColors.background,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            NoticeIcons.info,
            size: AppSizes.iconSmall,
            color: context.tokens.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: context.tokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// The patient's number on the request page. A refusal of the number (one's
/// own number, or a person with a circle of their own) is said under it;
/// any other refusal of the request is a toast.
class RequestPatientPhone extends StatelessWidget {
  const RequestPatientPhone({
    super.key,
    required this.controller,
    required this.state,
    required this.cubit,
  });

  final TextEditingController controller;
  final SendCircleRequestState state;
  final SendCircleRequestCubit cubit;

  /// The refusals that are about the number itself.
  static const Set<String> _numberKeys = <String>{
    'circles.self_request',
    'circles.patient_has_circle',
  };

  @override
  Widget build(BuildContext context) {
    final String? key = state.errorKey;
    final String? numberError = _numberKeys.contains(key)
        ? context.tr(key!)
        : null;
    return ErrorToast(
      errorKey: numberError == null ? key : null,
      child: PhoneField(
        controller: controller,
        label: context.tr('circles.patient_phone_label'),
        autofocus: false,
        showError: state.showErrors && !state.phoneValid,
        error: numberError,
        onChanged: (String typed) =>
            cubit.phoneChanged(ArabicDigits.digitsOnly(typed)),
      ),
    );
  }
}

/// «الوضع المقترح» and the two modes a request can propose for the
/// patient's app, as cards that each say what the mode means.
class RequestModeChoices extends StatelessWidget {
  const RequestModeChoices({
    super.key,
    required this.mode,
    required this.onChoose,
  });

  final CircleAppMode mode;
  final ValueChanged<CircleAppMode> onChoose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InsetText.header(context.tr('circles.proposed_mode')),
        const SizedBox(height: AppSpacing.sm),
        // Both modes and what each one means, on the screen at once.
        ChoiceCard(
          icon: PeopleIcons.user,
          title: context.tr('circles.mode_detailed'),
          hint: context.tr('circles.mode_detailed_hint'),
          selected: mode == CircleAppMode.detailed,
          onTap: () => onChoose(CircleAppMode.detailed),
        ),
        const SizedBox(height: AppSpacing.sm),
        ChoiceCard(
          icon: CareIcons.heart,
          title: context.tr('circles.mode_simplified'),
          hint: context.tr('circles.mode_simplified_hint'),
          selected: mode == CircleAppMode.simplified,
          onTap: () => onChoose(CircleAppMode.simplified),
        ),
      ],
    );
  }
}
