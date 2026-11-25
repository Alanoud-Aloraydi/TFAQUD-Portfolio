import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/constants/name_limits.dart';
import 'package:app/core/errors/invalid_birth_date_failure.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/feedback/error_toast.dart';
import 'package:app/core/widgets/forms/field_with_error.dart';
import 'package:app/core/widgets/forms/labeled_text_field.dart';
import 'package:app/core/widgets/forms/picker_field.dart';
import 'package:app/core/widgets/layout/step_header.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/widgets/account_load_failed.dart';
import 'package:app/features/circles/presentation/widgets/circle_basics_fields.dart';
import 'package:app/features/circles/presentation/widgets/circle_basics_scaffold.dart';
import 'package:app/features/circles/presentation/widgets/circle_feature_tile.dart';
import 'package:app/features/circles/presentation/widgets/circle_name_chips.dart';
import 'package:app/features/circles/presentation/widgets/create_circle_name_state.dart';
import 'package:app/features/circles/presentation/widgets/patient_city_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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

/// Everything on the page of a person without the app, above the create
/// button: the title, one line on what the circle is for, and the fields.
/// A refusal of the birth date is under its field; any other is a toast.
class PatientBasicsForm extends StatelessWidget {
  const PatientBasicsForm({
    required this.state,
    required this.cubit,
    required this.firstName,
    required this.lastName,
    super.key,
  });

  final CreateCircleState state;
  final CreateCircleCubit cubit;
  final TextEditingController firstName;
  final TextEditingController lastName;

  @override
  Widget build(BuildContext context) {
    const SizedBox gap = SizedBox(height: AppSpacing.lg);
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const PatientFormHeader(),
          PatientNameFields(
            state: state,
            cubit: cubit,
            firstName: firstName,
            lastName: lastName,
          ),
          gap,
          PatientBirthField(state: state, cubit: cubit),
          gap,
          PatientCityField(state: state, cubit: cubit),
          ErrorToast(
            errorKey: isBirthDateError(state.errorKey) ? null : state.errorKey,
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// The title of the page of a person without the app, and one line on what
/// the circle is for. Nothing else is explained on the page.
class PatientFormHeader extends StatelessWidget {
  const PatientFormHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StepHeader(
          title: context.tr('circles.patient_title'),
          subtitle: context.tr('circles.patient_subtitle'),
          onBack: context.canPop() ? () => context.pop() : null,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// The first and last name of the person being cared for.
class PatientNameFields extends StatelessWidget {
  const PatientNameFields({
    required this.state,
    required this.cubit,
    required this.firstName,
    required this.lastName,
    super.key,
  });

  final CreateCircleState state;
  final CreateCircleCubit cubit;
  final TextEditingController firstName;
  final TextEditingController lastName;

  @override
  Widget build(BuildContext context) {
    final String required = context.tr('common.field_required');
    return Column(
      children: <Widget>[
        LabeledTextField(
          label: context.tr('circles.patient_first_name'),
          controller: firstName,
          maxLength: NameLimits.name,
          onChanged: cubit.patientFirstNameChanged,
          errorText: state.showErrors && state.patientFirstName.trim().isEmpty
              ? required
              : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        LabeledTextField(
          label: context.tr('circles.patient_last_name'),
          controller: lastName,
          maxLength: NameLimits.name,
          textInputAction: TextInputAction.done,
          onChanged: cubit.patientLastNameChanged,
          errorText: state.showErrors && state.patientLastName.trim().isEmpty
              ? required
              : null,
        ),
      ],
    );
  }
}

/// The patient's birth date picker; required. The server's refusal of the
/// date is shown under it.
class PatientBirthField extends StatelessWidget {
  const PatientBirthField({
    required this.state,
    required this.cubit,
    super.key,
  });

  final CreateCircleState state;
  final CreateCircleCubit cubit;

  @override
  Widget build(BuildContext context) {
    final DateTime? date = state.birthDate;
    final String? refused = isBirthDateError(state.errorKey)
        ? context.tr(state.errorKey!)
        : null;
    return FieldWithError.reveal(
      error: refused,
      child: PickerField(
        label: context.tr('circles.birth_date'),
        hint: context.tr('circles.birth_date_hint'),
        icon: ScheduleIcons.calendar,
        value: date == null ? null : formatBirthDate(context, date),
        note: birthDateNote(context, date),
        onTap: () => pickPatientBirthDate(context, cubit, date),
        errorText:
            refused ??
            (state.showErrors && date == null
                ? context.tr('common.field_required')
                : null),
      ),
    );
  }
}

/// The circle for the person's own care (PROFILE-01) on one page: only its
/// name. Their name, birth date and city come from the account (onboarding
/// saved them); an account made before onboarding asked for them is asked
/// here.
/// The health condition and allergies are filled later in the medical file.
/// Needs a [CreateCircleCubit] of the self flow above it.
class SelfCircleBasicsScreen extends StatefulWidget {
  const SelfCircleBasicsScreen({super.key});

  @override
  State<SelfCircleBasicsScreen> createState() => _SelfCircleBasicsScreenState();
}

class _SelfCircleBasicsScreenState extends State<SelfCircleBasicsScreen>
    with CreateCircleNameState<SelfCircleBasicsScreen> {
  @override
  Widget build(BuildContext context) {
    final CreateCircleCubit cubit = context.read<CreateCircleCubit>();
    return CircleBasicsScaffold(
      onCreate: () => create(cubit),
      children: (BuildContext context, CreateCircleState state) => <Widget>[
        StepHeader(
          title: context.tr('circles.self_title'),
          subtitle: context.tr('circles.self_subtitle'),
          onBack: context.canPop() ? () => context.pop() : null,
        ),
        const SizedBox(height: AppSpacing.xl),
        CircleNameChips(cubit: cubit, state: state, customName: customName),
        // The one line under the title says who sees the name;
        // nothing more here.
        if (state.accountLoad == AccountLoad.failed) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          AccountLoadFailed(onRetry: cubit.loadAccount),
        ],
        CircleBasicsFields(cubit: cubit, state: state, topGap: AppSpacing.xl),
        CircleBasicsError(state: state),
      ],
    );
  }
}
