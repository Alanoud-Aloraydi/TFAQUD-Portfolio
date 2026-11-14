import 'dart:convert';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/services/reminders/dose_reminders.dart'
    show ReminderCircle, SnoozedTask, TaskSnooze;
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/repositories/appointments_repository_domain.dart';
import 'package:app/features/appointments/domain/use_cases/appointments_use_case.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/repositories/measurements_repository_domain.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/repositories/medications_repository_domain.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/widget_harness.dart';

/// One event on the fake calendar.
typedef _Event = ({
  String title,
  DateTime start,
  bool repeats,
  String? note,
  String? place,
  List<Duration>? reminders,
  String? zone,
  String? calendar,
  DateTime? until,
});

/// An event of an older version, in the phone's default calendar.
_Event _older(String title, DateTime start) => (
  title: title,
  start: start,
  repeats: false,
  note: null,
  place: null,
  reminders: null,
  zone: null,
  calendar: null,
  until: null,
);

extension on _Event {
  /// The same event, in the calendar [id].
  _Event withCalendar(String id) => (
    title: title,
    start: start,
    repeats: repeats,
    note: note,
    place: place,
    reminders: reminders,
    zone: zone,
    calendar: id,
    until: until,
  );
}

/// The phone's calendar, in memory.
class _Calendar extends Fake implements DeviceCalendar {
  final Map<String, _Event> events = <String, _Event>{};

  /// The calendars made on the phone: id → name. The phone's default one
  /// is not here (an event in it has no calendar).
  final Map<String, String> calendars = <String, String>{};
  int _next = 0;

  /// The phone takes no new calendar (no account that allows one).
  bool noNewCalendars = false;

  CalendarPermissionStatus status = CalendarPermissionStatus.granted;

  /// What the person answers when asked for full access.
  CalendarPermissionStatus answer = CalendarPermissionStatus.granted;
  int asked = 0;

  @override
  AutoPermissionMode? autoPermissions;

  /// The calendar gives an event another id, as a synced account can.
  void renumber(String id) {
    events['moved-$id'] = events.remove(id)!;
  }

  @override
  Future<CalendarPermissionStatus> hasPermissions() async => status;

  @override
  Future<CalendarPermissionStatus> requestPermissions({
    CalendarAccessLevel level = CalendarAccessLevel.full,
  }) async {
    asked++;
    return status = answer;
  }

  @override
  Future<String> createEvent({
    String? calendarId,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    bool isAllDay = false,
    String? description,
    String? location,
    String? url,
    String? timeZone,
    EventAvailability availability = EventAvailability.busy,
    RecurrenceRule? recurrenceRule,
    List<Duration>? reminders,
    EventOptionsAndroid? android,
  }) async {
    if (calendarId != null && !calendars.containsKey(calendarId)) {
      throw const DeviceCalendarException(
        errorCode: DeviceCalendarError.notFound,
        message: 'no such calendar',
      );
    }
    final String id = 'event-${_next++}';
    events[id] = (
      title: title,
      start: startDate,
      repeats: recurrenceRule != null,
      note: description,
      place: location,
      reminders: reminders,
      zone: timeZone,
      calendar: calendarId,
      until: switch (recurrenceRule?.end) {
        final UntilEnd end => end.until,
        _ => null,
      },
    );
    return id;
  }

  void _needFull() {
    if (status != CalendarPermissionStatus.granted) {
      throw const DeviceCalendarException(
        errorCode: DeviceCalendarError.permissionDenied,
        message: 'full access needed',
      );
    }
  }

  @override
  Future<List<Calendar>> listCalendars() async {
    _needFull();
    return <Calendar>[
      for (final MapEntry<String, String> entry in calendars.entries)
        Calendar(id: entry.key, name: entry.value, readOnly: false),
    ];
  }

  @override
  Future<String> createCalendar({
    required String name,
    String? colorHex,
    CalendarOptionsAndroid? android,
    CalendarOptionsIos? ios,
  }) async {
    _needFull();
    if (noNewCalendars) {
      throw const DeviceCalendarException(
        errorCode: DeviceCalendarError.calendarUnavailable,
        message: 'no source',
      );
    }
    final String id = 'calendar-${_next++}';
    calendars[id] = name;
    return id;
  }

  @override
  Future<void> deleteCalendar(String calendarId) async {
    _needFull();
    if (calendars.remove(calendarId) == null) {
      throw const DeviceCalendarException(
        errorCode: DeviceCalendarError.notFound,
        message: 'no such calendar',
      );
    }
    // Its events go with it.
    events.removeWhere((String _, _Event e) => e.calendar == calendarId);
  }

  /// The events in the calendar named [name].
  Iterable<_Event> inCalendar(String name) => events.values.where(
    (_Event e) => e.calendar != null && calendars[e.calendar] == name,
  );

  void _remove(String id, {required bool repeats}) {
    _needFull();
    final _Event? event = events[id];
    if (event == null) {
      throw const DeviceCalendarException(
        errorCode: DeviceCalendarError.notFound,
        message: 'no such event',
      );
    }
    expect(event.repeats, repeats);
    events.remove(id);
  }

  @override
  Future<void> deleteEvent({required String instanceId}) async =>
      _remove(instanceId, repeats: false);

  @override
  Future<void> deleteRecurring(String instanceId, EventSpan span) async {
    expect(span, EventSpan.allEvents);
    _remove(instanceId, repeats: true);
  }

  @override
  Future<List<Event>> listEvents(
    DateTime startDate,
    DateTime endDate, {
    List<String>? calendarIds,
  }) async => <Event>[
    for (final MapEntry<String, _Event> entry in events.entries)
      if (!entry.value.start.isBefore(startDate) &&
          entry.value.start.isBefore(endDate))
        Event(
          eventId: entry.key,
          instanceId: entry.key,
          calendarId: entry.value.calendar ?? 'default',
          title: entry.value.title,
          startDate: entry.value.start,
          endDate: entry.value.start.add(const Duration(hours: 1)),
          isAllDay: false,
          availability: EventAvailability.free,
          status: EventStatus.confirmed,
          isRecurring: entry.value.repeats,
        ),
  ];
}

class _Medications extends Fake implements MedicationsRepositoryDomain {
  @override
  Future<Result<List<MedicationPlan>, Failure>> getPlans(
    String circleId,
  ) async => const Success(<MedicationPlan>[]);
}

class _Measurements extends Fake implements MeasurementsRepositoryDomain {
  List<MeasurementPlan> list = const <MeasurementPlan>[];

  @override
  Stream<String> get changes => const Stream<String>.empty();

  @override
  Future<List<MeasurementPlan>> plans(String circleId) async => list;
}

/// A glucose reading every day at 08:00, from the first of November.
final MeasurementPlan _reading = MeasurementPlan(
  id: 'plan-1',
  kind: MeasurementKind.glucose,
  version: MeasurementVersion(
    id: 'version-1',
    number: 1,
    effectiveFromOn: DateTime(2026, 11, 1),
    time: '08:00',
    weekdays: const <int>[1, 2, 3, 4, 5, 6, 7],
    missedAfterMinutes: 60,
  ),
  history: const <MeasurementVersion>[],
);

class _Appointments extends Fake implements AppointmentsRepositoryDomain {
  final Map<String, List<CareAppointment>> visits =
      <String, List<CareAppointment>>{};
  bool offline = false;

  @override
  Stream<String> get changes => const Stream<String>.empty();

  @override
  Future<List<CareAppointment>> appointments(String circleId) async {
    if (offline) throw Exception('offline');
    return visits[circleId] ?? const <CareAppointment>[];
  }
}

/// A follow-up at «عيادة السكري» in three days at [time], at «الحبيب».
CareAppointment _visit({String id = 'a-1', String time = '16:30'}) {
  final DateTime day = DateTime.now().add(const Duration(days: 3));
  return CareAppointment(
    id: id,
    specialty: 'عيادة السكري',
    kind: AppointmentKind.followUp,
    otherKind: null,
    scheduledOn: DateTime(day.year, day.month, day.day),
    time: time,
    place: 'الحبيب',
    remoteMethod: null,
    companions: const <AppointmentCompanion>[],
    status: AppointmentStatus.scheduled,
    updatedAt: DateTime.utc(2026, 11),
  );
}

/// Nora's circle, on her own phone.
const ReminderCircle _circle = ReminderCircle(
  id: 'c-1',
  name: 'دائرة نورة',
  viewerId: 'nora',
  viewerIsPatient: true,
  timeZone: 'Asia/Riyadh',
);

final CalendarEventTexts _texts = CalendarEventTexts(
  dose: (String circleId, String medicine) => 'dose $medicine',
  doseNote: () => 'dose note',
  measurement: (String circleId, MeasurementKind kind) => 'read ${kind.name}',
  appointment: (String circleId, CareAppointment visit) =>
      'visit ${visit.specialty}',
  appointmentNote: (CareAppointment visit) => 'at ${visit.time}',
);

void main() {
  group('CalendarSync', () {
    late _Calendar calendar;
    late _Appointments appointments;
    late CalendarSync sync;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await EasyLocalization.ensureInitialized();
    });

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      calendar = _Calendar();
      appointments = _Appointments()
        ..visits[_circle.id] = <CareAppointment>[_visit()];
      sync = CalendarSync(
        MedicationsUseCase(_Medications()),
        MeasurementsUseCase(_Measurements()),
        AppointmentsUseCase(appointments),
        calendar: calendar,
        texts: _texts,
      );
    });

    Future<void> turnOn() async {
      await sync.sync(<ReminderCircle>[_circle]);
      await sync.setEnabled(
        _circle.id,
        CalendarSyncCategory.appointments,
        true,
      );
    }

    Future<void> turnOff() =>
        sync.setEnabled(_circle.id, CalendarSyncCategory.appointments, false);

    test(
      'an appointment is added with its words, place and reminders',
      () async {
        await turnOn();

        final _Event event = calendar.events.values.single;
        expect(event.title, 'visit عيادة السكري');
        expect(event.note, 'at 16:30');
        expect(event.place, 'الحبيب');
        expect(event.repeats, isFalse);
        // The same as its notifications: a day before, and two hours before.
        expect(event.reminders, const <Duration>[
          Duration(days: 1),
          Duration(hours: 2),
        ]);
      },
    );

    test(
      "an event is at the patient's time, kept in the patient's zone",
      () async {
        // The patient lives in London: the visit at 16:30 is 16:30 there,
        // whatever zone this phone (the test machine) is in, and the calendar
        // keeps it in London's zone across DST.
        const ReminderCircle london = ReminderCircle(
          id: 'c-1',
          name: 'دائرة نورة',
          viewerId: 'nora',
          viewerIsPatient: true,
          timeZone: 'Europe/London',
        );
        await sync.sync(<ReminderCircle>[london]);
        await sync.setEnabled(
          london.id,
          CalendarSyncCategory.appointments,
          true,
        );

        final _Event event = calendar.events.values.single;
        final CareAppointment visit = _visit();
        expect(event.zone, 'Europe/London');
        expect(
          event.start,
          london.clock.momentOf(visit.scheduledOn, visit.time).toLocal(),
        );
      },
    );

    test(
      'the injected clock decides whether an appointment is still ahead',
      () async {
        final CareAppointment visit = _visit();
        final DateTime at = _circle.clock
            .momentOf(visit.scheduledOn, visit.time)
            .toLocal();
        final CalendarSync lateSync = CalendarSync(
          MedicationsUseCase(_Medications()),
          MeasurementsUseCase(_Measurements()),
          AppointmentsUseCase(appointments),
          calendar: calendar,
          texts: _texts,
          clock: () => at.add(const Duration(minutes: 1)),
        );

        await lateSync.sync(<ReminderCircle>[_circle]);
        await lateSync.setEnabled(
          _circle.id,
          CalendarSyncCategory.appointments,
          true,
        );

        expect(calendar.events, isEmpty);
      },
    );

    test('turning the switch off takes the events off the calendar', () async {
      await turnOn();
      expect(calendar.events, hasLength(1));

      await turnOff();

      expect(calendar.events, isEmpty);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('calendar_sync_events'), isNull);
    });

    test(
      'with add-only access it asks once, and deletes once allowed',
      () async {
        await turnOn();
        calendar
          ..status = CalendarPermissionStatus.writeOnly
          ..answer = CalendarPermissionStatus.writeOnly;

        await turnOff();
        // Not allowed yet: the event stays, and is remembered.
        expect(calendar.asked, 1);
        expect(calendar.events, hasLength(1));
        await sync.refresh();
        expect(calendar.asked, 1);

        // Allowed in the Settings app later.
        calendar.status = CalendarPermissionStatus.granted;
        await sync.refresh();

        expect(calendar.events, isEmpty);
      },
    );

    test('an event the calendar gave another id is still found', () async {
      await turnOn();
      calendar.renumber(calendar.events.keys.single);

      await turnOff();

      expect(calendar.events, isEmpty);
    });

    test('a circle that cannot be read now keeps its events', () async {
      await turnOn();
      appointments.offline = true;

      await sync.refresh();
      expect(calendar.events, hasLength(1));

      // Turned off while offline: off the calendar all the same.
      await turnOff();
      expect(calendar.events, isEmpty);
    });

    test('an edited appointment replaces its event', () async {
      await turnOn();
      appointments.visits[_circle.id] = <CareAppointment>[
        _visit(time: '18:00'),
      ];

      await sync.refresh();

      expect(calendar.events.values.single.note, 'at 18:00');
    });

    test('an event of the older wording is replaced', () async {
      final CareAppointment visit = _visit();
      SharedPreferences.setMockInitialValues(<String, Object>{
        'calendar_sync_selections': <String>['c-1:appointments'],
        'calendar_sync_events': jsonEncode(<String, String>{
          'appointment:a-1:${visit.scheduledOn.toIso8601String()}:16:30':
              'old-1',
        }),
      });
      calendar.events['old-1'] = _older(
        'دائرة نورة · السكري',
        DateTime.now().add(const Duration(days: 3)),
      );

      await sync.sync(<ReminderCircle>[_circle]);

      expect(calendar.events.keys, isNot(contains('old-1')));
      expect(calendar.events.values.single.title, 'visit عيادة السكري');
    });

    test('before the circles are known, nothing is taken off', () async {
      await turnOn();
      final CalendarSync later = CalendarSync(
        MedicationsUseCase(_Medications()),
        MeasurementsUseCase(_Measurements()),
        AppointmentsUseCase(appointments),
        calendar: calendar,
        texts: _texts,
      );

      // Another switch, on a page opened before the home data loaded.
      await later.setEnabled('c-2', CalendarSyncCategory.doses, true);

      expect(calendar.events, hasLength(1));
    });

    test('signing out takes every event off but keeps the switches', () async {
      await turnOn();

      await sync.clear();

      expect(calendar.events, isEmpty);
      // Signing back in puts them back: the person asked for this circle's
      // appointments once and does not have to ask again.
      expect(
        await sync.isEnabled(_circle.id, CalendarSyncCategory.appointments),
        isTrue,
      );
    });

    test("the events go in the app's own «تفقّد» calendar", () async {
      await turnOn();

      expect(calendar.calendars.values, <String>['تفقّد']);
      expect(calendar.inCalendar('تفقّد'), hasLength(1));
    });

    test('signing out deletes the whole «تفقّد» calendar', () async {
      await turnOn();
      // One more, made before this version, in the default calendar.
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> saved = jsonDecode(
        prefs.getString('calendar_sync_events')!,
      ) as Map<String, dynamic>;
      final DateTime start = DateTime.now().add(const Duration(days: 5));
      calendar.events['old-1'] = _older('visit عيادة السكري', start);
      saved['appointment:a-0:old'] = 'old-1';
      await prefs.setString('calendar_sync_events', jsonEncode(saved));

      await sync.clear();

      expect(calendar.calendars, isEmpty);
      expect(calendar.events, isEmpty);
      expect(prefs.getString('calendar_sync_events'), isNull);
    });

    test('turning every switch off deletes the empty calendar', () async {
      await turnOn();

      await turnOff();

      expect(calendar.calendars, isEmpty);
    });

    test('a «تفقّد» calendar left by an earlier install goes first, with '
        'its events', () async {
      // Deleting the app left its calendar; this install never made it.
      calendar.calendars['left'] = 'تفقّد';
      calendar.events['left-1'] = _older(
        'visit عيادة السكري',
        DateTime.now().add(const Duration(days: 3)),
      ).withCalendar('left');

      await turnOn();

      expect(calendar.calendars.keys, isNot(contains('left')));
      expect(calendar.calendars.values, <String>['تفقّد']);
      expect(calendar.events.keys, isNot(contains('left-1')));
      expect(calendar.inCalendar('تفقّد'), hasLength(1));
    });

    test('a calendar deleted in the Calendar app is made again, with its '
        'events', () async {
      await turnOn();
      final String deleted = calendar.calendars.keys.single;
      await calendar.deleteCalendar(deleted);

      await sync.refresh();

      expect(calendar.calendars.keys.single, isNot(deleted));
      expect(calendar.inCalendar('تفقّد'), hasLength(1));
    });

    test('without full access the events go in the default calendar', () async {
      calendar
        ..status = CalendarPermissionStatus.writeOnly
        ..answer = CalendarPermissionStatus.writeOnly;

      await turnOn();

      expect(calendar.calendars, isEmpty);
      expect(calendar.events.values.single.calendar, isNull);
    });

    test('a phone that takes no new calendar uses its default one', () async {
      calendar.noNewCalendars = true;

      await turnOn();

      expect(calendar.events.values.single.calendar, isNull);
    });

    group('a repeating event', () {
      late DateTime now;
      late _Measurements measurements;
      late CalendarSync repeating;

      setUp(() {
        now = DateTime.utc(2026, 11, 10, 9);
        measurements = _Measurements()..list = <MeasurementPlan>[_reading];
        repeating = CalendarSync(
          MedicationsUseCase(_Medications()),
          MeasurementsUseCase(measurements),
          AppointmentsUseCase(_Appointments()),
          calendar: calendar,
          texts: _texts,
          clock: () => now,
        );
      });

      Future<void> turnOnReadings() async {
        await repeating.sync(<ReminderCircle>[_circle]);
        await repeating.setEnabled(
          _circle.id,
          CalendarSyncCategory.measurements,
          true,
        );
      }

      test('repeats two weeks ahead, no further', () async {
        await turnOnReadings();

        final _Event event = calendar.events.values.single;
        expect(event.repeats, isTrue);
        expect(event.until, now.add(const Duration(days: 14)));
      });

      test('is made again, two weeks ahead, once one week is left', () async {
        await turnOnReadings();
        final String first = calendar.events.keys.single;

        // Six days on: more than a week left, nothing changes.
        now = now.add(const Duration(days: 6));
        await repeating.refresh();
        expect(calendar.events.keys.single, first);

        // Eight days on: less than a week left.
        now = now.add(const Duration(days: 2));
        await repeating.refresh();
        final _Event again = calendar.events.values.single;
        expect(calendar.events.keys.single, isNot(first));
        expect(again.until, now.add(const Duration(days: 14)));
        expect(calendar.inCalendar('تفقّد'), hasLength(1));
      });

      test('of an older version, with no end, is replaced by one that has '
          "an end, in the app's calendar", () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'calendar_sync_selections': <String>['c-1:measurements'],
          'calendar_sync_events': jsonEncode(<String, Object>{
            'v2:c-1:measurements:version-1:0:08:00': <String, String>{
              'id': 'old-1',
              'title': 'read glucose',
            },
          }),
        });
        calendar.events['old-1'] = (
          title: 'read glucose',
          start: now,
          repeats: true,
          note: null,
          place: null,
          reminders: null,
          zone: null,
          calendar: null,
          until: null,
        );

        await repeating.sync(<ReminderCircle>[_circle]);

        expect(calendar.events.keys, isNot(contains('old-1')));
        final _Event event = calendar.inCalendar('تفقّد').single;
        expect(event.until, isNotNull);
      });
    });

    testWidgets('the words follow the reminders', (WidgetTester tester) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const <Locale>[Locale('ar')],
          startLocale: const Locale('ar'),
          path: 'assets/translations',
          assetLoader: const TestTranslations(),
          // The translations load through the app's localization delegates.
          child: Builder(
            builder: (BuildContext context) => MaterialApp(
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              home: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      CareVoice.update(<String, String?>{'c-noura': 'نورة', 'c-me': null});
      addTearDown(CareVoice.clear);

      expect(calendarEventTexts.dose('c-me', 'أنسولين'), 'لا ننسى الأنسولين');
      expect(
        calendarEventTexts.dose('c-noura', 'البنادول'),
        'لا ننسى البنادول لـنورة',
      );
      expect(calendarEventTexts.doseNote(), 'حان موعد الدواء');
      expect(
        calendarEventTexts.measurement('c-noura', MeasurementKind.glucose),
        'وقت القياس: سكر الدم لـنورة',
      );
      expect(
        calendarEventTexts.appointment('c-me', _visit()),
        'لا ننسى موعدك: مراجعة · عيادة السكري',
      );
      expect(
        calendarEventTexts.appointment('c-noura', _visit()),
        'لا ننسى موعد نورة: مراجعة · عيادة السكري',
      );
      expect(
        calendarEventTexts.appointmentNote(_visit()),
        'مراجعة · عيادة السكري · الساعة 4:30 م · الحبيب',
      );
    });

    group('a task put off', () {
      late ValueNotifier<Map<String, TaskSnooze>> snoozes;
      late CalendarSync putOff;

      setUp(() {
        appointments.visits.clear();
        snoozes = ValueNotifier<Map<String, TaskSnooze>>(
          const <String, TaskSnooze>{},
        );
        putOff = CalendarSync(
          MedicationsUseCase(_Medications()),
          MeasurementsUseCase(_Measurements()),
          AppointmentsUseCase(appointments),
          snoozes: snoozes,
          calendar: calendar,
          texts: _texts,
        );
      });

      TaskSnooze dose(Duration after) => TaskSnooze(
        circleId: _circle.id,
        task: SnoozedTask.dose,
        subject: 'ميتفورمين',
        at: DateTime.now().toUtc().add(after),
      );

      test('gets one event at its new time, moved when put off again, and '
          'gone once it ends', () async {
        await putOff.sync(<ReminderCircle>[_circle]);
        await putOff.setEnabled(_circle.id, CalendarSyncCategory.doses, true);

        final TaskSnooze first = dose(const Duration(minutes: 15));
        snoozes.value = <String, TaskSnooze>{'c-1|s|2026-11-9': first};
        await pumpEventQueue();

        expect(calendar.events.values.single.title, 'dose ميتفورمين');
        expect(calendar.events.values.single.start, first.at.toLocal());
        expect(calendar.events.values.single.repeats, isFalse);
        expect(calendar.events.values.single.note, 'dose note');
        expect(calendar.events.values.single.reminders, <Duration>[
          Duration.zero,
        ]);

        final TaskSnooze again = dose(const Duration(hours: 1));
        snoozes.value = <String, TaskSnooze>{'c-1|s|2026-11-9': again};
        await pumpEventQueue();
        expect(calendar.events.values.single.start, again.at.toLocal());

        // Recorded, or its time came.
        snoozes.value = const <String, TaskSnooze>{};
        await pumpEventQueue();
        expect(calendar.events, isEmpty);
      });

      test('in a category that is off, gets no event', () async {
        await putOff.sync(<ReminderCircle>[_circle]);
        await putOff.setEnabled(_circle.id, CalendarSyncCategory.doses, true);

        snoozes.value = <String, TaskSnooze>{
          'c-1|measurement|v|08:00|2026-11-9': TaskSnooze(
            circleId: _circle.id,
            task: SnoozedTask.measurement,
            subject: MeasurementKind.bp.name,
            at: DateTime.now().toUtc().add(const Duration(minutes: 15)),
          ),
        };
        await pumpEventQueue();

        expect(calendar.events, isEmpty);
      });
    });
  });
}
