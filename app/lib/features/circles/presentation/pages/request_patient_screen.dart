import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:app/core/widgets/inline_error.dart';
import 'package:app/core/widgets/pill_button.dart';
import 'package:app/core/widgets/step_header.dart';
import 'package:app/features/auth/presentation/widgets/phone_field.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/circle_label.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_cubit.dart';
import 'package:app/features/circles/presentation/cubit/send_circle_request_state.dart';
import 'package:app/features/circles/presentation/widgets/circle_label_picker.dart';
import 'package:app/features/circles/presentation/widgets/request_sent_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The page that asks a patient who uses the app for a circle (CREAT-04): the
/// patient's phone number, the word the circle is named with, and the mode
/// proposed for the patient's app. Once the request is sent, the same page shows
/// the waiting state (CREAT-05). Needs a [SendCircleRequestCubit] above it.
class RequestPatientScreen extends StatefulWidget {
  const RequestPatientScreen({super.key});

  @override
  State<RequestPatientScreen> createState() => _RequestPatientScreenState();
}

class _RequestPatientScreenState extends State<RequestPatientScreen> {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _customLabel = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _customLabel.dispose();
    super.dispose();
  }

  Future<void> _send(BuildContext context, SendCircleRequestCubit cubit) async {
    final CircleLabel label = cubit.state.label;
    await cubit.send(labelName: context.tr('circles.label.${label.name}'));
  }

  @override
  Widget build(BuildContext context) {
    final SendCircleRequestCubit cubit = context.read<SendCircleRequestCubit>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: BlocConsumer<SendCircleRequestCubit, SendCircleRequestState>(
            listenWhen:
                (SendCircleRequestState before, SendCircleRequestState after) =>
                    after.sessionEnded && !before.sessionEnded,
            listener: (BuildContext context, SendCircleRequestState state) =>
                context.go(Routes.auth),
            builder: (BuildContext context, SendCircleRequestState state) {
              final sent = state.sent;
              if (sent != null) return RequestSentView(request: sent);
              return _form(context, cubit, state);
            },
          ),
        ),
      ),
    );
  }

  Widget _form(
    BuildContext context,
    SendCircleRequestCubit cubit,
    SendCircleRequestState state,
  ) {
    final TextTheme text = Theme.of(context).textTheme;
    final String requiredText = context.tr('circles.field_required');
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                StepHeader(
                  title: context.tr('circles.request_title'),
                  onBack: context.canPop() ? () => context.pop() : null,
                ),
                const SizedBox(height: 24),
                PhoneField(
                  controller: _phone,
                  label: context.tr('circles.patient_phone_label'),
                  autofocus: false,
                  showError: state.showErrors && !cubit.isPhoneValid,
                  onChanged: (String typed) =>
                      cubit.phoneChanged(ArabicDigits.digitsOnly(typed)),
                ),
                const SizedBox(height: 24),
                CircleLabelPicker(
                  selected: state.label,
                  onSelected: cubit.chooseLabel,
                  customController: _customLabel,
                  onCustomChanged: cubit.customLabelChanged,
                  hint: circleLabelHint(
                    context,
                    label: state.label,
                    customLabel: state.customLabel,
                  ),
                  customError:
                      state.showErrors && state.customLabel.trim().isEmpty
                      ? requiredText
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  context.tr('circles.proposed_mode'),
                  style: text.titleSmall?.copyWith(color: AppColors.ink2),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<CircleAppMode>(
                    // In a right-to-left language the first segment is on the
                    // right: detailed, then simplified, as in the design.
                    segments: <ButtonSegment<CircleAppMode>>[
                      ButtonSegment<CircleAppMode>(
                        value: CircleAppMode.detailed,
                        label: Text(context.tr('circles.mode_detailed')),
                      ),
                      ButtonSegment<CircleAppMode>(
                        value: CircleAppMode.simplified,
                        label: Text(context.tr('circles.mode_simplified')),
                      ),
                    ],
                    selected: <CircleAppMode>{state.mode},
                    showSelectedIcon: false,
                    onSelectionChanged: (Set<CircleAppMode> modes) =>
                        cubit.chooseMode(modes.first),
                    style: SegmentedButton.styleFrom(
                      foregroundColor: AppColors.ink2,
                      selectedForegroundColor: AppColors.brand,
                      selectedBackgroundColor: AppColors.brandTint,
                      side: const BorderSide(color: AppColors.fieldBorder),
                    ).copyWith(
                      minimumSize: const WidgetStatePropertyAll<Size>(
                        Size.fromHeight(48),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    state.mode == CircleAppMode.simplified
                        ? 'circles.mode_simplified_hint'
                        : 'circles.mode_detailed_hint',
                  ),
                  style: text.bodySmall?.copyWith(color: AppColors.ink3),
                ),
                const SizedBox(height: 24),
                _Notice(text: context.tr('circles.request_notice')),
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
          label: context.tr('circles.send_request'),
          isLoading: state.status == SendStatus.sending,
          onPressed: () => _send(context, cubit),
        ),
      ],
    );
  }
}

/// The yellow note above the send button: the patient is asked, and nothing is
/// created without the patient's agreement. The icon keeps the colour from being
/// the only signal.
class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningTint,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_outline, size: 20, color: AppColors.warningInk),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.warningInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
