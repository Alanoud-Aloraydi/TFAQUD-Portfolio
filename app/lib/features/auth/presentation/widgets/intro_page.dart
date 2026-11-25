import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/constants/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/task_button.dart';
import 'package:app/core/widgets/feedback/attention_box.dart';
import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/navigation/glass_capsule_button.dart';
import 'package:app/core/widgets/overlays/glass_menu_layout.dart';
import 'package:app/core/widgets/overlays/glass_menu_row.dart';
import 'package:app/features/circles/domain/entities/circle_member.dart';
import 'package:app/features/circles/domain/entities/edit_access.dart';
import 'package:app/features/circles/presentation/widgets/member_open_row.dart';
import 'package:app/features/medications/presentation/widgets/attention_dose_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The welcome's pages, each a real part of the app with example data.
const List<Widget> introPages = <Widget>[
  IntroPage(picture: IntroCirclesPicture(), words: 'intro.p1'),
  IntroPage(picture: IntroMembersPicture(), words: 'intro.p2'),
  IntroPage(picture: IntroAttentionPicture(), words: 'intro.p3'),
];

/// A page: the picture in the middle of the room left, then the title and
/// one line. With large text the page scrolls instead of overflowing.
class IntroPage extends StatelessWidget {
  const IntroPage({super.key, required this.picture, required this.words});

  final Widget picture;

  /// The page's keys in ar.json: `$words.title` and `$words.body`.
  final String words;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final TextStyle? body = text.bodyLarge?.copyWith(
      color: AppSemanticColors.textSupporting,
    );
    return CustomScrollView(
      primary: false,
      slivers: <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.sm,
              children: <Widget>[
                // An example, not the app: it takes no taps. It sits in the
                // middle of the room left at its own height; the scroll
                // view keeps it from stretching to all of it.
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      primary: false,
                      child: IgnorePointer(child: picture),
                    ),
                  ),
                ),
                Text(context.tr('$words.title'), style: text.displaySmall),
                Text(context.tr('$words.body'), style: body),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Page 1: the circle switcher of the top bar, open on three circles.
class IntroCirclesPicture extends StatelessWidget {
  const IntroCirclesPicture({super.key});

  @override
  Widget build(BuildContext context) {
    final String khalid = context.tr('intro.demo.khalid_circle');
    Widget row(String label, [IconData? icon]) => GlassMenuRow(
      entry: GlassMenuEntry(
        value: label,
        label: label,
        icon: icon,
        selected: label == khalid,
      ),
      height: GlassMenuLayout.rowHeight(context),
    );
    return Column(
      spacing: AppSpacing.md,
      children: <Widget>[
        GlassCapsuleButton(
          label: khalid,
          semanticLabel: khalid,
          icon: ArrowIcons.caretDown,
          onPressed: null,
          leading: PersonPhoto(
            name: khalid,
            photoPath: '',
            avatarCode: 'gh_3',
            size: 26,
          ),
        ),
        GlassSurface(
          borderRadius: BorderRadius.circular(AppRadius.l),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: <Widget>[
                row(khalid),
                row(context.tr('intro.demo.noura_circle')),
                row(context.tr('intro.demo.my_care')),
                const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
                row(context.tr('topbar.add_circle'), ActionIcons.plus),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Page 3: «يحتاج انتباهك» of «اليوم», with one dose gone past its time.
class IntroAttentionPicture extends StatelessWidget {
  const IntroAttentionPicture({super.key});

  @override
  Widget build(BuildContext context) {
    String tr(String key) => context.tr(key);
    final Color red = context.tokens.error;
    return AttentionBox(
      title: tr('today_dashboard.attention'),
      count: 1,
      // The white card of a late dose, as AttentionMedicationCard draws it.
      child: TodayRowCard(
        child: Column(
          spacing: AppSpacing.sm,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.tight,
              children: <Widget>[
                CircleAvatar(
                  radius: 17,
                  backgroundColor: red.withValues(alpha: .08),
                  child: Icon(TafaqodPhosphorIcons.pill, color: red, size: 18),
                ),
                Expanded(
                  child: AttentionDoseText(
                    title: tr('intro.demo.dose'),
                    when: tr('intro.demo.dose_when'),
                    how: tr('intro.demo.dose_how'),
                  ),
                ),
              ],
            ),
            TaskButtonGrid(
              answer: TaskButton(
                role: TaskButtonRole.answer,
                icon: CupertinoIcons.checkmark,
                label: tr('medications.taken_short_other'),
                onPressed: () {},
              ),
              choices: <Widget>[
                TaskButton(
                  role: TaskButtonRole.skip,
                  icon: CupertinoIcons.minus_circle,
                  label: tr('medications.skip_short'),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Page 2: the members of a circle as «الدائرة» lists them: the patient,
/// you as its leader, and a member who edits the medicines only.
class IntroMembersPicture extends StatelessWidget {
  const IntroMembersPicture({super.key});

  @override
  Widget build(BuildContext context) {
    String name(String key) => context.tr('intro.demo.$key');
    final List<CircleMember> members = <CircleMember>[
      CircleMember(
        name: name('khalid'),
        isYou: false,
        isPatient: true,
        avatarCode: 'gh_3',
      ),
      CircleMember(
        name: name('leen'),
        isYou: true,
        isLeader: true,
        avatarCode: 'w1_1',
      ),
      CircleMember(
        name: name('alanoud'),
        isYou: false,
        avatarCode: 'w7_1',
        access: const EditAccess(
          medications: true,
          measurements: false,
          appointments: false,
        ),
      ),
    ];
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: AppSemanticColors.surfaceContent,
        shape: AppRadius.shape(AppRadius.m),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          children: <Widget>[
            for (final CircleMember member in members) ...<Widget>[
              if (member != members.first)
                const Divider(
                  height: AppSizes.divider,
                  color: AppSemanticColors.borderPlan,
                ),
              MemberRowContent(
                member: member,
                photoPath: '',
                patientUsesApp: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
