import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/loading/skeleton.dart';
import 'package:app/core/widgets/loading/skeleton_line.dart';
import 'package:app/core/widgets/loading/skeleton_page.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/presentation/cubit/emergency_card_cubit.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_body.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

/// What the page holds for one state of the card: the skeleton, the retry,
/// or the card itself in the language chosen, with the ambulance button.
class EmergencyCardContent extends StatelessWidget {
  const EmergencyCardContent({
    super.key,
    required this.state,
    required this.cardKey,
    required this.english,
    required this.onLanguage,
  });

  final EmergencyCardState state;

  /// The picture of the card for the PDF is taken from here.
  final GlobalKey cardKey;
  final bool english;
  final ValueChanged<bool> onLanguage;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case EmergencyCardStatus.loading:
        return const EmergencyCardSkeleton();
      case EmergencyCardStatus.failure:
        return EmergencyCardFailure(
          messageKey: state.messageKey,
          onRetry: context.read<EmergencyCardCubit>().load,
        );
      case EmergencyCardStatus.ready:
        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: <Widget>[
            EmergencyLanguageSwitch(english: english, onChanged: onLanguage),
            const SizedBox(height: AppSpacing.md),
            RepaintBoundary(
              key: cardKey,
              child: Directionality(
                textDirection: english ? TextDirection.ltr : TextDirection.rtl,
                child: EmergencyCardBody(
                  card: state.card!,
                  birthDate: state.birthDate,
                  words: EmergencyCardText(context, english: english),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const AmbulanceButton(),
          ],
        );
    }
  }
}

/// The red «اتصال بالإسعاف» button under the card; it calls
/// [EmergencyNumber.ambulance].
class AmbulanceButton extends StatelessWidget {
  const AmbulanceButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () =>
          launchUrl(Uri(scheme: 'tel', path: EmergencyNumber.ambulance)),
      style: FilledButton.styleFrom(
        backgroundColor: AppSemanticColors.statusError,
        foregroundColor: AppSemanticColors.surfaceContent,
        minimumSize: const Size.fromHeight(AppSizes.button),
      ),
      icon: const Icon(CareIcons.siren, size: AppSizes.icon),
      label: Text(
        context.tr(
          'emergency_card.ambulance',
          args: <String>[EmergencyNumber.ambulance],
        ),
      ),
    );
  }
}

/// «عربي / English»: two segments on a light track; the chosen one is
/// white with a line edge.
class EmergencyLanguageSwitch extends StatelessWidget {
  const EmergencyLanguageSwitch({
    super.key,
    required this.english,
    required this.onChanged,
  });

  final bool english;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: const ShapeDecoration(
        color: AppSemanticColors.segmentTrack,
        shape: StadiumBorder(),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: EmergencySegment(
              label: context.tr('emergency_card.lang_ar'),
              selected: !english,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: EmergencySegment(
              label: 'English',
              selected: english,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class EmergencySegment extends StatelessWidget {
  const EmergencySegment({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double _height = 36;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? AppSemanticColors.surfaceContent
            : AppSemanticColors.transparent,
        shape: StadiumBorder(
          side: selected
              ? const BorderSide(color: AppSemanticColors.borderPlan)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: _height,
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected
                      ? AppSemanticColors.textPrimary
                      : AppSemanticColors.textSupporting,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The emergency card while it loads: the dark name card (drawn as one
/// shape, since its real color is ink) and the details card with its
/// sections.
class EmergencyCardSkeleton extends StatelessWidget {
  const EmergencyCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonPage(
      padding: EdgeInsets.zero,
      scrollInsets: false,
      children: <Widget>[
        SkeletonBox(height: 132, radius: AppRadius.l),
        SizedBox(height: AppSpacing.lg),
        SkeletonSurface(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            children: <Widget>[
              SectionSkeleton(valueWidth: 0.3),
              Divider(height: AppSizes.divider),
              SectionSkeleton(valueWidth: 0.7),
              Divider(height: AppSizes.divider),
              SectionSkeleton(valueWidth: 0.55, lines: 2),
            ],
          ),
        ),
      ],
    );
  }
}

class SectionSkeleton extends StatelessWidget {
  const SectionSkeleton({super.key, required this.valueWidth, this.lines = 1});

  final double valueWidth;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SkeletonLine(widthFactor: 0.3, height: 12),
          for (int i = 0; i < lines; i++) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            SkeletonLine(widthFactor: valueWidth, height: 16),
          ],
        ],
      ),
    );
  }
}

/// The card could not be read: why, and a button that reads it again.
class EmergencyCardFailure extends StatelessWidget {
  const EmergencyCardFailure({
    super.key,
    required this.messageKey,
    required this.onRetry,
  });

  final String? messageKey;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            context.tr(messageKey ?? 'error.unknown'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: onRetry,
            child: Text(context.tr('auth.retry')),
          ),
        ],
      ),
    );
  }
}
