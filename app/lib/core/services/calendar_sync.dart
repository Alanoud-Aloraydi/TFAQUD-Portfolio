import 'dart:async';
import 'dart:convert';

import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/services/permissions/app_permission.dart';
import 'package:app/core/services/reminder_circle.dart';
import 'package:app/core/services/reminders/dose_reminders.dart'
    show TaskSnooze;
import 'package:app/core/services/reminders/reminder_payloads.dart'
    show SnoozedTask;
import 'package:app/core/services/service_texts.dart';
import 'package:app/core/utils/coalescing_runner.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/use_cases/appointments_use_case.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_plan.dart';
import 'package:app/features/measurements/domain/measurement_version.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:shared_preferences/shared_preferences.dart';

part 'calendar/state.dart';
part 'calendar/key_parts.dart';
part 'calendar/event_texts.dart';
part 'calendar/event_words.dart';
part 'calendar/desired_event.dart';
part 'calendar/saved_event.dart';
part 'calendar/keys.dart';
part 'calendar/lifecycle.dart';
part 'calendar/selections.dart';
part 'calendar/run.dart';
part 'calendar/snoozes.dart';
part 'calendar/doses.dart';
part 'calendar/measurements.dart';
part 'calendar/appointments.dart';
part 'calendar/reconcile.dart';
part 'calendar/own_calendar.dart';
part 'calendar/saved_store.dart';
part 'calendar/device_events.dart';
part 'calendar/plan_time.dart';
part 'calendar/moments.dart';
part 'calendar/calendar_sync_class.dart';

/// One kind of event this feature can mirror, switched on per circle.
enum CalendarSyncCategory { doses, measurements, appointments }
