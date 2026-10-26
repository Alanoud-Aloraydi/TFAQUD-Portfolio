import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/core/widgets/labeled_text_field.dart';
import 'package:app/core/widgets/pill_button.dart';
import 'package:app/features/circles/presentation/cubit/create_self_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_self_circle_state.dart';
import 'package:app/features/circles/presentation/widgets/birth_date_sheet.dart';
import 'package:app/features/circles/presentation/widgets/circle_step_header.dart';
import 'package:app/features/circles/presentation/widgets/city_sheet.dart';
import 'package:app/features/circles/presentation/widgets/option_chips.dart';
import 'package:app/features/circles/presentation/widgets/picker_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Step 1 of 3 of the circle for your own care (PROFILE-01): the name of the
/// circle, the birth date and the city. Needs a [CreateSelfCircleCubit] above
/// it.
class SelfCircleBasicsScreen extends StatefulWidget {
  const SelfCircleBasicsScreen({super.key});

  @override
  State<SelfCircleBasicsScreen> createState() => _SelfCircleBasicsScreenState();
}

class _SelfCircleBasicsScreenState extends State<SelfCircleBasicsScreen> {
  late final TextEditingController _customName;

  @override
  void initState() {
    super.initState();
    _customName = TextEditingController(
      text: context.read<CreateSelfCircleCubit>().state.customName,
    );
  }

  @override
  void dispose() {
    _customName.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate(
    BuildContext context,
    CreateSelfCircleCubit cubit,
    DateTime? current,
  ) async {
    final DateTime? picked = await showBirthDateSheet(
      context,
      selected: current,
    );
    if (picked != null) cubit.birthDateChanged(picked);
  }

  Future<void> _pickCity(
    BuildContext context,
    CreateSelfCircleCubit cubit,
    String? current,
  ) async {
    final String? picked = await showCitySheet(context, selected: current);
    if (picked != null) cubit.cityChanged(picked);
  }

  void _next(BuildContext context, CreateSelfCircleCubit cubit) {
    final NamePreset preset = cubit.state.namePreset;
    final bool ok = cubit.continueFromBasics(
      presetName: context.tr('circles.preset.${preset.name}'),
    );
    if (ok) context.push(Routes.createSelfCircleHealth);
  }

  /// The date as the field shows it, "12 مارس 1964": the day and the year are
  /// written with the digits 0 to 9, like every number of the app.
  String _formatDate(BuildContext context, DateTime date) {
    final String month = context.tr('circles.months.${date.month}');
    return '${date.day} $month ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final CreateSelfCircleCubit cubit = context.read<CreateSelfCircleCubit>();
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: BlocBuilder<CreateSelfCircleCubit, CreateSelfCircleState>(
            builder: (BuildContext context, CreateSelfCircleState state) {
              if (state.alreadyHasCircle) return const _AlreadyHasCircle();
              final String requiredText = context.tr('circles.field_required');
              return Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          CircleStepHeader(
                            step: 1,
                            stepTitle: context.tr('circles.step_basics'),
                            title: context.tr('circles.self_title'),
                            onBack: context.canPop()
                                ? () => context.pop()
                                : null,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            context.tr('circles.circle_name'),
                            style: text.titleSmall?.copyWith(
                              color: AppColors.ink2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          OptionChips(
                            options: <ChipOption>[
                              for (final NamePreset preset in NamePreset.values)
                                ChipOption(
                                  preset.name,
                                  context.tr('circles.preset.${preset.name}'),
                                ),
                            ],
                            isSelected: (String code) =>
                                code == state.namePreset.name,
                            onTap: (String code) => cubit.choosePreset(
                              NamePreset.values.byName(code),
                            ),
                          ),
                          if (state.namePreset == NamePreset.other)
                            ...<Widget>[
                              const SizedBox(height: 12),
                              LabeledTextField(
                                label: context.tr('circles.custom_name'),
                                controller: _customName,
                                maxLength:
                                    CreateSelfCircleCubit.maxCustomNameLength,
                                textInputAction: TextInputAction.done,
                                onChanged: cubit.customNameChanged,
                                errorText:
                                    state.showErrors &&
                                        state.customName.trim().isEmpty
                                    ? requiredText
                                    : null,
                              ),
                            ],
                          const SizedBox(height: 8),
                          Text(
                            context.tr('circles.name_hint'),
                            style: text.bodySmall?.copyWith(
                              color: AppColors.ink3,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _AccountNameField(
                            state: state,
                            onRetry: cubit.loadAccount,
                          ),
                          const SizedBox(height: 16),
                          PickerField(
                            label: context.tr('circles.birth_date'),
                            hint: context.tr('circles.birth_date_hint'),
                            icon: Icons.calendar_today_outlined,
                            value: state.birthDate == null
                                ? null
                                : _formatDate(context, state.birthDate!),
                            onTap: () => _pickBirthDate(
                              context,
                              cubit,
                              state.birthDate,
                            ),
                            errorText:
                                state.showErrors && state.birthDate == null
                                ? requiredText
                                : null,
                          ),
                          const SizedBox(height: 16),
                          PickerField(
                            label: context.tr('circles.city'),
                            hint: context.tr('circles.city_hint'),
                            icon: Icons.location_on_outlined,
                            value: state.city,
                            onTap: () => _pickCity(context, cubit, state.city),
                            errorText: state.showErrors && state.city == null
                                ? requiredText
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PillButton(
                    label: context.tr('circles.next'),
                    onPressed: () => _next(context, cubit),
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

/// Shown instead of the form when the account already has a circle for its own
/// care: the person learns it at once, before filling anything in.
class _AlreadyHasCircle extends StatelessWidget {
  const _AlreadyHasCircle();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      children: <Widget>[
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.check_circle_outline,
                size: 56,
                color: AppColors.brand,
              ),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(
                  context.tr('circles.already_title'),
                  textAlign: TextAlign.center,
                  style: text.headlineSmall,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('circles.already_has_circle'),
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: AppColors.ink2),
              ),
            ],
          ),
        ),
        PillButton(
          label: context.tr('circles.back_home'),
          onPressed: () => context.go(Routes.today),
        ),
      ],
    );
  }
}

/// The patient's name, read from the account and not editable ("من حسابك").
/// It shows a spinner while the names load, and a retry link when they fail.
class _AccountNameField extends StatelessWidget {
  const _AccountNameField({required this.state, required this.onRetry});

  final CreateSelfCircleState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Widget content = switch (state.accountLoad) {
      AccountLoad.loaded => Text(
        state.fullName ?? '',
        style: text.bodyLarge,
      ),
      AccountLoad.loading => const Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      AccountLoad.failed => Row(
        children: <Widget>[
          Flexible(
            child: Text(
              context.tr('circles.name_failed'),
              style: text.bodyMedium?.copyWith(color: AppColors.dangerInk),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(context.tr('auth.retry'))),
        ],
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.tr('circles.name'),
          style: text.titleSmall?.copyWith(color: AppColors.ink2),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: AppColors.sunken,
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
          child: Row(
            children: <Widget>[
              Expanded(child: content),
              const SizedBox(width: 12),
              Text(
                context.tr('circles.from_account'),
                style: text.bodySmall?.copyWith(color: AppColors.ink3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
