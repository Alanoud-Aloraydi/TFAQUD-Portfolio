import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_kind_choices.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/domain/entities/prayer_period.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/measurement_verdict.dart';
import 'package:app/features/simplified_mode/presentation/widgets/medicine_photo.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_chip.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_family_member_photo.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_snoozed_line.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_chips.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_texts.dart';
import 'package:flutter/material.dart';

/// Inside the next card: the picture with its period on the corner, then
/// the words.
class SimplifiedNextContent extends StatelessWidget {
  const SimplifiedNextContent({
    super.key,
    required this.task,
    required this.day,
    required this.when,
  });

  final TodayTask task;
  final SimplifiedDay day;

  /// «التالي، بعد ساعتين», or what the task was put off to.
  final String when;

  @override
  Widget build(BuildContext context) {
    final PrayerPeriod? period = simplifiedNextPeriod(task, day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Stack(
          children: <Widget>[
            SimplifiedNextHero(task: task, day: day),
            if (period != null) SimplifiedNextPeriodBadge(period: period),
          ],
        ),
        SimplifiedNextText(task: task, day: day, when: when),
      ],
    );
  }
}

/// «بعد المغرب», the pill on the corner of the next card's picture.
class SimplifiedNextPeriodBadge extends StatelessWidget {
  const SimplifiedNextPeriodBadge({super.key, required this.period});

  final PrayerPeriod period;

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      top: 14,
      start: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: SimplifiedColors.surface,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          simplifiedPeriod(context, period),
          style: SimplifiedStyle.head(SimplifiedStyle.caption),
        ),
      ),
    );
  }
}

/// The mark of something done, in the colours of the detailed mode's «تم
/// أخذها»: a green check on the pale green, ringed in the same green so it
/// stands on any ground. The same on «تم، يعطيك العافية» and on the home's
/// «خلّصت مهام اليوم». Decorative: the words beside it say what was done.
class SimplifiedDoneMark extends StatelessWidget {
  const SimplifiedDoneMark({super.key, required this.size});

  /// The circle's width; the check is half of it.
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: SimplifiedColors.successTint,
        shape: BoxShape.circle,
        border: Border.all(color: SimplifiedColors.success, width: size / 36),
      ),
      child: Icon(
        ActionIcons.check,
        size: size / 2,
        color: SimplifiedColors.success,
      ),
    ),
  );
}

/// What the next card says under its picture: when, the time, the name and
/// what to take.
class SimplifiedNextText extends StatelessWidget {
  const SimplifiedNextText({
    super.key,
    required this.task,
    required this.day,
    required this.when,
  });

  final TodayTask task;
  final SimplifiedDay day;

  /// «التالي، بعد ساعتين», or what the task was put off to.
  final String when;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(SimplifiedStyle.pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SimplifiedSnoozedLine(
            text: when,
            task: task,
            day: day,
            style: SimplifiedStyle.label(
              SimplifiedStyle.caption,
              color: task.status == TodayTaskStatus.late
                  ? SimplifiedColors.attentionInk
                  : SimplifiedColors.muted,
            ),
          ),
          Text(
            simplifiedTime(context, task.time),
            style: SimplifiedStyle.head(SimplifiedStyle.time, height: 1.1),
          ),
          const Divider(height: 28, color: SimplifiedColors.line),
          Text(
            simplifiedTaskTitle(context, task),
            style: SimplifiedStyle.head(SimplifiedStyle.name),
          ),
          SimplifiedTaskDetails(task: task, day: day),
        ],
      ),
    );
  }
}

/// The picture on top of the next card: the medicine's photo, or the tile
/// of a measurement or a visit.
class SimplifiedNextHero extends StatelessWidget {
  const SimplifiedNextHero({super.key, required this.task, required this.day});

  final TodayTask task;
  final SimplifiedDay day;

  @override
  Widget build(BuildContext context) {
    if (task.kind == TodayTaskKind.medication) {
      return MedicinePhoto(
        circleId: day.circleId,
        planId: task.dose!.planId,
        height: 210,
        radius: 0,
        iconSize: 96,
      );
    }
    final bool measurement = task.kind == TodayTaskKind.measurement;
    return Container(
      height: 150,
      width: double.infinity,
      color: measurement
          ? CareVisuals.measurementTile
          : CareVisuals.appointmentTile,
      child: Icon(
        measurement
            ? measurementIcon(task.measurement!.kind)
            : appointmentKindIcon(task.appointment!.kind),
        size: 80,
        color: AppSettingsTileColors.onTile,
      ),
    );
  }
}

/// Under a task's name on the home card: what to take, its short notes,
/// and who comes along to a visit, each one's photo before their name.
class SimplifiedTaskDetails extends StatelessWidget {
  const SimplifiedTaskDetails({
    super.key,
    required this.task,
    required this.day,
  });

  final TodayTask task;
  final SimplifiedDay day;

  @override
  Widget build(BuildContext context) {
    final List<String> notes = simplifiedTaskNotes(context, task, day);
    final List<AppointmentCompanion> companions =
        task.appointment?.companions ?? const <AppointmentCompanion>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (task.dose case final dose?) ...<Widget>[
          const SizedBox(height: 6),
          SimplifiedDoseLine(
            dose: dose,
            strength: simplifiedDoseReason(task, day) == null,
          ),
        ],
        if (notes.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final String note in notes) SimplifiedChip(note),
            ],
          ),
        ],
        if (companions.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          SimplifiedCompanions(circleId: day.circleId, companions: companions),
        ],
      ],
    );
  }
}

/// What to take of a dose, on one line: «حبة واحدة», and the strength
/// beside it when [strength] asks for it.
class SimplifiedDoseLine extends StatelessWidget {
  const SimplifiedDoseLine({
    super.key,
    required this.dose,
    required this.strength,
  });

  final DoseOccurrence dose;

  /// False when the medicine's reason is shown as a chip under this line
  /// («الكوليسترول»): the reason tells the medicines apart, so the
  /// strength is not repeated.
  final bool strength;

  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.end,
    spacing: 10,
    children: <Widget>[
      Text(
        simplifiedDoseAmount(context, dose),
        style: SimplifiedStyle.head(SimplifiedStyle.headline),
      ),
      if (strength)
        Text(
          simplifiedStrength(context, dose),
          style: SimplifiedStyle.text(
            SimplifiedStyle.body,
            weight: AppTextTheme.medium,
          ),
        ),
    ],
  );
}
