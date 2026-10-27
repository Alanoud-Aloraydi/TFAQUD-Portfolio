import 'package:app/core/navigation/routers.dart';
import 'package:app/core/widgets/pill_button.dart';
import 'package:app/features/circles/presentation/circle_flow_routes.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_cubit.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';
import 'package:app/features/circles/presentation/widgets/account_name_field.dart';
import 'package:app/features/circles/presentation/widgets/already_has_circle_view.dart';
import 'package:app/features/circles/presentation/widgets/birth_date_sheet.dart';
import 'package:app/features/circles/presentation/widgets/circle_step_header.dart';
import 'package:app/features/circles/presentation/widgets/city_sheet.dart';
import 'package:app/features/circles/presentation/widgets/picker_field.dart';
import 'package:app/features/circles/presentation/widgets/read_only_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Step 1 of 3 after the patient agreed to a request (PROFILE-01C): the name
/// comes from the account, the circle name was set by the sender, and the
/// patient gives the birth date and the city. Needs a [CreateCircleCubit] of the
/// approved flow above it.
class ApprovedCircleBasicsScreen extends StatelessWidget {
  const ApprovedCircleBasicsScreen({super.key});

  Future<void> _pickBirthDate(
    BuildContext context,
    CreateCircleCubit cubit,
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
    CreateCircleCubit cubit,
    String? current,
  ) async {
    final String? picked = await showCitySheet(context, selected: current);
    if (picked != null) cubit.cityChanged(picked);
  }

  void _next(BuildContext context, CreateCircleCubit cubit) {
    if (cubit.continueFromApprovedBasics()) {
      context.push(cubit.flow.healthRoute, extra: cubit.request);
    }
  }

  @override
  Widget build(BuildContext context) {
    final CreateCircleCubit cubit = context.read<CreateCircleCubit>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: BlocBuilder<CreateCircleCubit, CreateCircleState>(
            builder: (BuildContext context, CreateCircleState state) {
              if (state.alreadyHasCircle) return const AlreadyHasCircleView();
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
                            title: context.tr('circles.approved_title'),
                            onBack: context.canPop()
                                ? () => context.pop()
                                : () => context.go(Routes.notifications),
                          ),
                          const SizedBox(height: 24),
                          AccountNameField(
                            state: state,
                            onRetry: cubit.loadAccount,
                          ),
                          const SizedBox(height: 16),
                          ReadOnlyField(
                            label: context.tr('circles.approved_circle_name'),
                            note: context.tr('circles.set_by_requester'),
                            child: Text(
                              state.circleName,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          const SizedBox(height: 16),
                          PickerField(
                            label: context.tr('circles.birth_date'),
                            hint: context.tr('circles.birth_date_hint'),
                            icon: Icons.calendar_today_outlined,
                            value: state.birthDate == null
                                ? null
                                : formatBirthDate(context, state.birthDate!),
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
