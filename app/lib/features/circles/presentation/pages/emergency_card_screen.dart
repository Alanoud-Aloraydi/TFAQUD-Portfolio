import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/core/widgets/back_link.dart';
import 'package:app/core/widgets/loading_widget.dart';
import 'package:app/features/circles/domain/entities/emergency_card.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/presentation/cubit/emergency_card_cubit.dart';
import 'package:app/features/circles/presentation/cubit/emergency_card_state.dart';
import 'package:app/features/circles/presentation/widgets/medical_texts.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The emergency card of a circle (CIRCLE-07): the patient's name and blood
/// type on a red card, then the allergies, the chronic conditions and the
/// people to call. It is read-only. Needs an [EmergencyCardCubit] above it.
class EmergencyCardScreen extends StatelessWidget {
  const EmergencyCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final EmergencyCardCubit cubit = context.read<EmergencyCardCubit>();
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<EmergencyCardCubit, EmergencyCardState>(
          listenWhen: (EmergencyCardState before, EmergencyCardState after) =>
              after.sessionEnded && !before.sessionEnded,
          listener: (BuildContext context, EmergencyCardState state) =>
              context.go(Routes.auth),
          builder: (BuildContext context, EmergencyCardState state) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  BackLink(
                    onPressed: context.canPop()
                        ? () => context.pop()
                        : () => context.go(Routes.circle),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            context.tr('circles.card_title'),
                            style: text.headlineMedium,
                          ),
                        ),
                      ),
                      const _ReadOnlyPill(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _body(context, cubit, state)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    EmergencyCardCubit cubit,
    EmergencyCardState state,
  ) {
    switch (state.status) {
      case EmergencyCardStatus.loading:
        return const LoadingWidget();
      case EmergencyCardStatus.failure:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                context.tr(state.messageKey ?? 'error.unknown'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: cubit.load,
                child: Text(context.tr('auth.retry')),
              ),
            ],
          ),
        );
      case EmergencyCardStatus.ready:
        final EmergencyCard card = state.card!;
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: <Widget>[
            _NameCard(card: card),
            const SizedBox(height: 16),
            _DetailsCard(card: card),
          ],
        );
    }
  }
}

/// "للقراءة فقط" with a lock: the card cannot be changed from here.
class _ReadOnlyPill extends StatelessWidget {
  const _ReadOnlyPill();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.sunken,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.lock_outline, size: 14, color: AppColors.ink2),
          const SizedBox(width: 4),
          Text(
            context.tr('circles.card_read_only'),
            style: text.bodySmall?.copyWith(color: AppColors.ink2),
          ),
        ],
      ),
    );
  }
}

/// The red card: the full name and the blood type in a round badge.
class _NameCard extends StatelessWidget {
  const _NameCard({required this.card});

  final EmergencyCard card;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String? bloodType = card.profile.bloodType;
    return MergeSemantics(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    card.fullName,
                    style: text.headlineMedium?.copyWith(
                      color: AppColors.onBrand,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.onBrand.withAlpha(51),
                  ),
                  child: Text(
                    // A dash when nobody entered the blood type yet.
                    bloodType ?? '—',
                    textDirection: TextDirection.ltr,
                    style: text.titleLarge?.copyWith(
                      color: AppColors.onBrand,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('circles.blood_type'),
              style: text.bodyMedium?.copyWith(color: AppColors.onBrand),
            ),
          ],
        ),
      ),
    );
  }
}

/// The white card: allergies, chronic conditions and the people to call.
class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.card});

  final EmergencyCard card;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: <Widget>[
          _Section(
            label: context.tr('circles.allergies_title'),
            child: Text(
              MedicalTexts.allergies(context, card.profile.allergies),
              style: text.bodyLarge,
            ),
          ),
          const Divider(height: 1),
          _Section(
            label: context.tr('circles.conditions'),
            child: Text(
              MedicalTexts.conditions(context, card.profile.conditions),
              style: text.bodyLarge,
            ),
          ),
          const Divider(height: 1),
          _Section(
            label: context.tr('circles.card_contact'),
            child: card.contacts.isEmpty
                ? Text(
                    context.tr('circles.card_no_contacts'),
                    style: text.bodyLarge,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final EmergencyContact contact
                          in card.contacts) ...<Widget>[
                        Text(
                          '${contact.name} '
                          '(${MedicalTexts.relation(context, contact)})',
                          style: text.bodyLarge,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            MedicalTexts.phone(contact),
                            textDirection: TextDirection.ltr,
                            style: text.bodyLarge?.copyWith(
                              color: AppColors.ink2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: text.titleSmall?.copyWith(color: AppColors.ink2),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}
