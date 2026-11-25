import 'dart:async';
import 'dart:convert';

import 'package:app/app/services/permissions/app_permission.dart';
import 'package:app/app/services/reminder_circle.dart';
import 'package:app/app/services/service_texts.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/care_voice.dart';
import 'package:app/core/reminders/task_snooze.dart';
import 'package:app/core/utils/coalescing_runner.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/domain/usecases/appointments_use_case.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_texts.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_plan.dart';
import 'package:app/features/measurements/domain/entities/measurement_version.dart';
import 'package:app/features/measurements/domain/usecases/measurements_use_case.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:shared_preferences/shared_preferences.dart';

part 'package:app/app/services/calendar/appointments.dart';
part 'package:app/app/services/calendar/calendar_sync_class.dart';
part 'package:app/app/services/calendar/desired_event.dart';
part 'package:app/app/services/calendar/device_events.dart';
part 'package:app/app/services/calendar/doses.dart';
part 'package:app/app/services/calendar/event_texts.dart';
part 'package:app/app/services/calendar/event_words.dart';
part 'package:app/app/services/calendar/key_parts.dart';
part 'package:app/app/services/calendar/keys.dart';
part 'package:app/app/services/calendar/measurements.dart';
part 'package:app/app/services/calendar/moments.dart';
part 'package:app/app/services/calendar/own_calendar.dart';
part 'package:app/app/services/calendar/plan_time.dart';
part 'package:app/app/services/calendar/reconcile.dart';
part 'package:app/app/services/calendar/run.dart';
part 'package:app/app/services/calendar/saved_event.dart';
part 'package:app/app/services/calendar/saved_store.dart';
part 'package:app/app/services/calendar/snoozes.dart';
part 'package:app/app/services/calendar/state.dart';

/// One kind of event this feature can mirror, switched on per circle.
enum CalendarSyncCategory { doses, measurements, appointments }
