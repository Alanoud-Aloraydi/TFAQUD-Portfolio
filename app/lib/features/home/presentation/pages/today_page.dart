import 'dart:async';

import 'package:app/app/services/dose_retention_memory.dart';
import 'package:app/app/services/weather/patient_weather.dart';
import 'package:app/core/localization/calendar_texts.dart';
import 'package:app/core/localization/care_voice.dart';
import 'package:app/core/localization/greeting.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/scroll_insets.dart';
import 'package:app/core/widgets/feedback/attention_box.dart';
import 'package:app/core/widgets/layout/large_title.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/home/presentation/cubit/dose_retention_cubit.dart';
import 'package:app/features/home/presentation/widgets/home_add_sheet.dart';
import 'package:app/features/home/presentation/widgets/record_header.dart';
import 'package:app/features/home/presentation/widgets/selected_circle_builder.dart';
import 'package:app/features/home/presentation/widgets/today_content.dart';
import 'package:app/features/home/presentation/widgets/today_snapshot.dart';
import 'package:app/features/home/presentation/widgets/weather_icon.dart';
import 'package:app/features/home/presentation/widgets/weather_now.dart';
import 'package:app/features/home/presentation/widgets/weather_sheet.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/medications/domain/entities/dose_retention.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «اليوم»: the weather in the patient's city and the greeting, the doses
/// about to be deleted, what needs attention, the next task and the day's
/// schedule by prayer period, all on the patient's clock.
class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SelectedCircleBuilder(
    builder: (context, circle) => SingleChildScrollView(
      padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TodayHeader(
            now: PatientClockScope.of(context).now(),
            // The weather where the patient lives, beside the date.
            weather: TodayWeather(
              latitude: circle.latitude,
              longitude: circle.longitude,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          DoseRetentionNotice(circleId: circle.id),
          TodayContent(
            circleId: circle.id,
            // Recording is open to a member who edits any area.
            canManage: circle.canRecord,
            onAdd: circle.canRecord
                ? () => showHomeAddSheet(context, circle: circle)
                : null,
          ),
        ],
      ),
    ),
  );
}

/// The weather now in the patient's city, on the date line under the
/// greeting of «اليوم»: its icon, the degrees in bold and the condition in
/// words. A tap opens it large with Apple's Weather mark and its data
/// sources. Nothing shows without the city's place or an answer, so the
/// page never waits for it.
class TodayWeather extends StatelessWidget {
  const TodayWeather({
    super.key,
    required this.latitude,
    required this.longitude,
    this.source,
  });

  final double? latitude;
  final double? longitude;

  /// The app's [WeatherSource] when null.
  final WeatherSource? source;

  @override
  Widget build(BuildContext context) => WeatherNow(
    latitude: latitude,
    longitude: longitude,
    source: source,
    builder: (BuildContext context, PatientWeather? weather) => weather == null
        ? const SizedBox.shrink()
        : WeatherCapsule(weather: weather),
  );
}

/// The weather as a tappable capsule: icon, degrees in bold and the
/// condition in words. A tap opens it large.
class WeatherCapsule extends StatelessWidget {
  const WeatherCapsule({super.key, required this.weather});

  final PatientWeather weather;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String condition = context.tr(
      'weather.condition.${weather.condition}',
    );
    void open() => unawaited(showWeatherSheet(context, weather, condition));
    return Semantics(
      button: true,
      label: spoken(
        context.tr(
          'weather.spoken',
          args: <String>['${weather.degrees}', condition],
        ),
      ),
      onTap: open,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.capsule),
        onTap: open,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.touch),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(weatherIcon(weather), size: AppSizes.iconSmall),
              const SizedBox(width: AppSpacing.tight),
              Text(
                context.tr(
                  'weather.degrees',
                  args: <String>['${weather.degrees}'],
                ),
                style: text.bodySmall?.copyWith(
                  fontWeight: AppTextTheme.bold,
                  color: AppSemanticColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.tight),
              Flexible(child: Text(condition, style: text.bodySmall)),
            ],
          ),
        ),
      ),
    );
  }
}

/// On «اليوم», five days before the doses of a day are deleted for good
/// (they are kept three months): what goes, and the way to export it
/// first. Nothing once exported or set aside, until the next days.
class DoseRetentionNotice extends StatelessWidget {
  const DoseRetentionNotice({super.key, required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    // Its own answer for each circle shown.
    key: ValueKey<String>(circleId),
    create: (_) =>
        DoseRetentionCubit(const DoseRetentionMemory(), circleId)..load(),
    child: BlocBuilder<DoseRetentionCubit, DoseRetentionRead>(
      builder: (BuildContext context, DoseRetentionRead memory) {
        final DateTime? through = memory.read
            ? DoseRetention.goingThrough(
                PatientClockScope.of(context).today(),
                context.watch<MedicationsCubit>().state.plans,
                memory.settled,
              )
            : null;
        if (through == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: AttentionBox(
            title: context.tr('dose_retention.title'),
            child: DoseRetentionActions(circleId: circleId, through: through),
          ),
        );
      },
    ),
  );
}

/// «صباح الخير، ياسر» from Fajr, «مساء الخير، ياسر» from Dhuhr, with
/// the patient's date under it and [weather] beside the date; the tab
/// keeps «اليوم».
class TodayHeader extends StatelessWidget {
  const TodayHeader({super.key, required this.now, this.weather});

  final DateTime now;
  final Widget? weather;

  @override
  Widget build(BuildContext context) {
    final PrayerDay? day = todayPrayerDay(
      context.watch<PrayerTimesCubit>().state,
      now,
    );
    final String weekday = context.tr('common.weekdays.${now.weekday}');
    final String date = calendarDate(context, now, year: false);
    return LargeTitle(
      title: greeting(
        context,
        now,
        CareVoice.viewerName,
        fajr: day?.times[Prayer.fajr],
        dhuhr: day?.times[Prayer.dhuhr],
      ),
      subtitle: '$weekday $date',
      subtitleTrailing: weather,
    );
  }
}

/// What the warning before doses are deleted says, and its two answers.
/// An export holds every dose until today, so the warning waits for the
/// doses after it; «لاحقًا» waits five days.
class DoseRetentionActions extends StatelessWidget {
  const DoseRetentionActions({
    super.key,
    required this.circleId,
    required this.through,
  });

  final String circleId;

  /// The last day whose doses go within five days.
  final DateTime through;

  Future<void> _export(BuildContext context) async {
    final DoseRetentionCubit cubit = context.read<DoseRetentionCubit>();
    final DateTime today = PatientClockScope.of(context).today();
    await showRecordExportSheet(
      context,
      circleId: circleId,
      plans: context.read<MedicationsCubit>().state.plans,
      measurementPlans: context.read<MeasurementPlansCubit>().state.plans,
    );
    await cubit.settle(today);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const SizedBox(height: AppSpacing.sm),
      Text(
        context.tr(
          'dose_retention.body',
          args: <String>[formatMedicationDate(context, through)],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      FilledButton(
        onPressed: () => _export(context),
        child: Text(context.tr('dose_retention.export')),
      ),
      TextButton(
        onPressed: () => context.read<DoseRetentionCubit>().settle(
          DoseRetention.laterThrough(through),
        ),
        child: Text(context.tr('dose_retention.later')),
      ),
    ],
  );
}
