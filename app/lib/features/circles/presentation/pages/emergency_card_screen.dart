import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/back_link.dart';
import 'package:app/core/widgets/layout/content_switcher.dart';
import 'package:app/features/circles/domain/entities/emergency_card.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/medical_options.dart';
import 'package:app/features/circles/presentation/cubit/emergency_card_cubit.dart';
import 'package:app/features/circles/presentation/cubit/emergency_card_state.dart';
import 'package:app/features/circles/presentation/widgets/circle_skeletons.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_export.dart';
import 'package:app/features/circles/presentation/widgets/medical_texts.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// The emergency card of a circle (CIRCLE-07), as in the handoff: one white
/// card with an ink edge that a stranger can read in a hurry (a paramedic, a
/// school, a neighbour). The red badge, the name and age, the blood type in
/// a dark box, the allergy in a red box, the chronic conditions, the current
/// medicines and the people to call. Under it the ambulance button and why
/// the card is separate from the medical file.
///
/// «عربي / English» switches the card's language; medicine names and typed
/// text stay as written. «تصدير» shares the card as a PDF. The card is
/// read-only. Needs an [EmergencyCardCubit] and a [MedicationsCubit] above
/// it.
class EmergencyCardScreen extends StatefulWidget {
  const EmergencyCardScreen({super.key});

  @override
  State<EmergencyCardScreen> createState() => _EmergencyCardScreenState();
}

class _EmergencyCardScreenState extends State<EmergencyCardScreen> {
  /// The picture of the card for the PDF is taken from here.
  final GlobalKey _cardKey = GlobalKey();
  bool _english = false;
  bool _exporting = false;

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String failed = context.tr('record_export.failed');
    bool shared;
    try {
      shared = await shareEmergencyCardPdf(
        boundary: _cardKey,
        title: context.tr('circles.card_title'),
      );
    } on Exception {
      shared = false;
    }
    if (!mounted) return;
    setState(() => _exporting = false);
    if (!shared) messenger.showSnackBar(SnackBar(content: Text(failed)));
  }

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
            final bool ready = state.status == EmergencyCardStatus.ready;
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      BackLink(
                        onPressed: context.canPop()
                            ? () => context.pop()
                            : () => context.go(Routes.circle),
                      ),
                      const Spacer(),
                      if (ready)
                        TextButton.icon(
                          onPressed: _exporting ? null : _export,
                          icon: const Icon(
                            AppIcons.export,
                            size: AppSizes.iconSmall,
                          ),
                          label: Text(context.tr('emergency_card.export')),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    header: true,
                    child: Text(
                      context.tr('circles.card_title'),
                      style: text.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    // Loading, error and content fade into each other.
                    child: ContentSwitcher(
                      stateKey: state.status,
                      child: _body(context, cubit, state),
                    ),
                  ),
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
        return const EmergencyCardSkeleton();
      case EmergencyCardStatus.failure:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                context.tr(state.messageKey ?? 'error.unknown'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: cubit.load,
                child: Text(context.tr('auth.retry')),
              ),
            ],
          ),
        );
      case EmergencyCardStatus.ready:
        final _CardText words = _CardText(context, english: _english);
        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: <Widget>[
            _LanguageSwitch(
              english: _english,
              onChanged: (bool english) => setState(() => _english = english),
            ),
            const SizedBox(height: AppSpacing.md),
            RepaintBoundary(
              key: _cardKey,
              child: Directionality(
                textDirection: _english ? TextDirection.ltr : TextDirection.rtl,
                child: _Card(
                  card: state.card!,
                  birthDate: state.birthDate,
                  words: words,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const _AmbulanceButton(),
            const SizedBox(height: AppSpacing.md),
            const _WhySeparate(),
          ],
        );
    }
  }
}

/// The card's words in the chosen language. Arabic reads the app's keys;
/// English reads `card_en`. Typed text (names, «other» items, medicine
/// names) is never translated.
class _CardText {
  _CardText(this.context, {required this.english});

  final BuildContext context;
  final bool english;

  String t(String key, {List<String>? args}) =>
      context.tr(english ? 'card_en.$key' : 'emergency_card.$key', args: args);

  String _code(String group, String code) =>
      context.tr(english ? 'card_en.$group.$code' : 'medical.$group.$code');

  String form(String name) =>
      context.tr(english ? 'card_en.form.$name' : 'medications.form.$name');

  String unit(String name) =>
      context.tr(english ? 'card_en.unit.$name' : 'medications.unit.$name');

  String relation(EmergencyContact contact) => english
      ? _code('relation', contact.relation)
      : MedicalTexts.relation(context, contact);

  String _join(List<String> items) =>
      items.where((String item) => item.trim().isNotEmpty).join(t('separator'));

  /// «72 سنة · مواليد 1954» or «72 years · born 1954».
  String age(DateTime birthDate) {
    final DateTime now = DateTime.now();
    int years = now.year - birthDate.year;
    final bool before =
        now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day);
    if (before) years -= 1;
    final bool few = years >= 3 && years <= 10;
    return t(
      few ? 'age_few' : 'age_many',
      args: <String>['$years', '${birthDate.year}'],
    );
  }

  String conditions(ConditionsDraft? answer) {
    if (answer == null) return t('unknown');
    if (answer.answer == ListAnswer.none) return t('no_conditions');
    return _join(<String>[
      for (final String code in answer.codes)
        code == MedicalOptions.other
            ? (answer.other ?? '')
            : _code('condition', code),
    ]);
  }

  /// The allergies that are listed, or null when there are none to show in
  /// the red box (none, or nobody answered).
  String? allergies(AllergiesDraft? answer) {
    if (answer == null || answer.answer == ListAnswer.none) return null;
    final String joined = _join(<String>[
      for (final String code in answer.medication)
        code == MedicalOptions.other
            ? (answer.otherMedication ?? '')
            : _code('medication', code),
      for (final String code in answer.food)
        code == MedicalOptions.other
            ? (answer.otherFood ?? '')
            : _code('food', code),
    ]);
    return joined.isEmpty ? null : joined;
  }

  String noAllergies(AllergiesDraft? answer) =>
      answer == null ? t('unknown') : t('no_allergies');
}

/// «عربي / English»: two segments on a light track; the chosen one is
/// white with a line edge.
class _LanguageSwitch extends StatelessWidget {
  const _LanguageSwitch({required this.english, required this.onChanged});

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
            child: _Segment(
              label: context.tr('emergency_card.lang_ar'),
              selected: !english,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _Segment(
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

/// Renders the segment element of emergency card screen.
class _Segment extends StatelessWidget {
  const _Segment({
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

/// The card itself: white, a 2-point ink edge, 16 inside.
class _Card extends StatelessWidget {
  const _Card({
    required this.card,
    required this.birthDate,
    required this.words,
  });

  final EmergencyCard card;
  final DateTime? birthDate;
  final _CardText words;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final DateTime? born = birthDate;
    final String? bloodType = card.profile.bloodType;
    final String? allergies = words.allergies(card.profile.allergies);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.inset),
      decoration: ShapeDecoration(
        color: AppSemanticColors.surfaceContent,
        shape: AppRadius.shape(
          AppRadius.m,
          side: const BorderSide(
            color: AppSemanticColors.textSupporting,
            width: AppSizes.borderEmphasis,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // The red badge and «للقراءة فقط».
          Row(
            children: <Widget>[
              _Badge(label: words.t('title')),
              const Spacer(),
              Icon(
                AppIcons.lock,
                size: AppSizes.iconSmall,
                color: context.tokens.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(words.t('read_only'), style: text.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // The name and age, and the blood type in the dark box.
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(card.fullName, style: text.headlineMedium),
                    if (born != null)
                      Text(words.age(born), style: text.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _BloodType(label: words.t('blood_type'), value: bloodType),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (allergies != null)
            _AllergyBox(label: words.t('allergy'), value: allergies)
          else
            _Line(
              label: words.t('allergies'),
              value: words.noAllergies(card.profile.allergies),
            ),
          const SizedBox(height: AppSpacing.md),
          _Line(
            label: words.t('conditions'),
            value: words.conditions(card.profile.conditions),
          ),
          const _Rule(),
          _Medicines(words: words),
          const _Rule(),
          _Contacts(contacts: card.contacts, words: words),
          const SizedBox(height: AppSpacing.md),
          Text(words.t('updated'), style: text.bodySmall),
        ],
      ),
    );
  }
}

/// The red capsule «بطاقة الطوارئ» with the first-aid mark.
class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: const ShapeDecoration(
        color: AppSemanticColors.statusError,
        shape: StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            AppIcons.firstAid,
            size: AppSizes.iconSmall,
            color: AppSemanticColors.surfaceContent,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: AppSemanticColors.surfaceContent),
          ),
        ],
      ),
    );
  }
}

/// The blood type in a dark box: the small label over the type, left to
/// right. A dash while nobody entered it.
class _BloodType extends StatelessWidget {
  const _BloodType({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: ShapeDecoration(
        color: AppSemanticColors.textPrimary,
        shape: AppRadius.shape(AppRadius.s),
      ),
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: text.bodySmall?.copyWith(
              color: AppSemanticColors.onInkSupporting,
            ),
          ),
          Text(
            value ?? '—',
            textDirection: TextDirection.ltr,
            style: text.headlineMedium?.copyWith(
              color: AppSemanticColors.surfaceContent,
            ),
          ),
        ],
      ),
    );
  }
}

/// The allergy in a light red box with a red edge: it is what a helper must
/// not miss.
class _AllergyBox extends StatelessWidget {
  const _AllergyBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: ShapeDecoration(
        color: AppSemanticColors.surfaceDanger,
        shape: AppRadius.shape(
          AppRadius.s,
          side: const BorderSide(color: AppSemanticColors.borderDanger),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            AppIcons.warning,
            size: AppSizes.icon,
            color: AppSemanticColors.statusError,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: text.labelMedium?.copyWith(
                    color: AppSemanticColors.statusError,
                  ),
                ),
                Text(
                  value,
                  style: text.headlineSmall?.copyWith(
                    color: AppSemanticColors.statusError,
                    fontWeight: AppTextTheme.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small grey label over its value.
class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: text.bodySmall),
        Text(value, style: text.titleMedium),
      ],
    );
  }
}

/// A thin line between the parts of the card, 12 above and below.
class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Divider(
        height: AppSizes.divider,
        color: AppSemanticColors.segmentTrack,
      ),
    );
  }
}

/// The current medicines: the name and strength at the start, the dose
/// times at the end.
class _Medicines extends StatelessWidget {
  const _Medicines({required this.words});

  final _CardText words;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return BlocBuilder<MedicationsCubit, MedicationsState>(
      builder: (BuildContext context, MedicationsState state) {
        final DateTime today = DateUtils.dateOnly(DateTime.now());
        final List<MedicationPlan> current = state.plans
            .where(
              (MedicationPlan plan) =>
                  !plan.isPreviousOn(today) && !plan.isScheduledOn(today),
            )
            .toList();
        final Widget content;
        if (state.status == MedicationsStatus.loading ||
            state.status == MedicationsStatus.initial) {
          content = const CupertinoActivityIndicator();
        } else if (state.status == MedicationsStatus.failure) {
          content = TextButton(
            onPressed: () => context.read<MedicationsCubit>().load(
              context.read<EmergencyCardCubit>().circleId,
            ),
            child: Text(context.tr(state.messageKey ?? 'error.unknown')),
          );
        } else if (current.isEmpty) {
          content = Text(
            words.t('no_current_medications'),
            style: text.titleSmall,
          );
        } else {
          content = Column(
            children: <Widget>[
              for (final MedicationPlan plan in current)
                _Medicine(plan: plan, words: words),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(words.t('current_medications'), style: text.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            content,
          ],
        );
      },
    );
  }
}

/// Renders the medicine element of emergency card screen.
class _Medicine extends StatelessWidget {
  const _Medicine({required this.plan, required this.words});

  final MedicationPlan plan;
  final _CardText words;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final TextStyle? small = text.bodySmall?.copyWith(
      color: AppSemanticColors.textSupporting,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(plan.version.name, style: text.titleSmall),
                // The strength is its own run, left to right, so «500 mg»
                // never turns into «mg 500».
                Wrap(
                  spacing: AppSpacing.xs,
                  children: <Widget>[
                    Text(
                      '${formatMedicationNumber(plan.version.strengthValue)} '
                      '${plan.version.strengthUnit.apiValue}',
                      textDirection: TextDirection.ltr,
                      style: small,
                    ),
                    Text('·', style: small),
                    Text(
                      words.form(plan.version.dosageForm.name),
                      style: small,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (final schedule in plan.version.schedules)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      schedule.time,
                      textDirection: TextDirection.ltr,
                      style: small,
                    ),
                    // «08:00 · 1 قرص»: a dot keeps the time and the dose
                    // apart.
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: Text('·', style: small),
                    ),
                    Text(
                      '${formatMedicationNumber(schedule.doseValue)} '
                      '${words.unit(schedule.doseUnit.name)}',
                      style: small,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// «اتصل بـ»: one row per person, the name and relation, the number left to
/// right, and the call mark. A tap calls.
class _Contacts extends StatelessWidget {
  const _Contacts({required this.contacts, required this.words});

  final List<EmergencyContact> contacts;
  final _CardText words;

  Future<void> _call(String number) async {
    final String digits = number.replaceAll(' ', '');
    await launchUrl(Uri(scheme: 'tel', path: digits));
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(words.t('call'), style: text.bodySmall),
        if (contacts.isEmpty)
          Text(words.t('no_contacts'), style: text.titleSmall),
        for (final EmergencyContact contact in contacts)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Material(
              color: AppSemanticColors.surfaceContent,
              shape: AppRadius.shape(AppRadius.s),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _call(MedicalTexts.phone(contact)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${contact.name} · ${words.relation(contact)}',
                          style: text.titleSmall,
                        ),
                      ),
                      Text(
                        MedicalTexts.phone(contact),
                        textDirection: TextDirection.ltr,
                        style: text.bodySmall,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(
                        AppIcons.phoneCall,
                        size: AppSizes.iconSmall,
                        color: AppSemanticColors.statusSuccess,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The red «اتصال بالإسعاف 997» under the card.
class _AmbulanceButton extends StatelessWidget {
  const _AmbulanceButton();

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => launchUrl(Uri(scheme: 'tel', path: '997')),
      style: FilledButton.styleFrom(
        backgroundColor: AppSemanticColors.statusError,
        foregroundColor: AppSemanticColors.surfaceContent,
        minimumSize: const Size.fromHeight(AppSizes.button),
      ),
      icon: const Icon(AppIcons.siren, size: AppSizes.icon),
      label: Text(context.tr('emergency_card.ambulance')),
    );
  }
}

/// «لماذا بطاقة منفصلة؟»: the medical file is for the family; the card is
/// for a stranger in a hurry.
class _WhySeparate extends StatelessWidget {
  const _WhySeparate();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.inset),
      decoration: ShapeDecoration(
        color: AppSemanticColors.surfaceContent,
        shape: AppRadius.shape(AppRadius.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(AppIcons.info, size: AppSizes.iconSmall),
              const SizedBox(width: AppSpacing.xs),
              Text(
                context.tr('emergency_card.why_title'),
                style: text.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(context.tr('emergency_card.why_text'), style: text.bodySmall),
        ],
      ),
    );
  }
}
