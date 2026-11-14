import 'package:app/core/errors/failure.dart';
import 'package:app/features/prayer_times/domain/prayer_day.dart';
import 'package:app/features/prayer_times/domain/repositories/prayer_times_repository_domain.dart';
import 'package:app/features/prayer_times/domain/use_cases/prayer_times_use_case.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_cubit.dart';
import 'package:app/features/prayer_times/presentation/cubit/prayer_times_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

/// Counts the reads and answers with the day it was given, or with
/// [failure] when it is set.
class _FakeRepository implements PrayerTimesRepositoryDomain {
  int reads = 0;
  Failure? failure;

  @override
  Future<Result<PrayerDay, Failure>> getToday(String circleId) async {
    reads++;
    if (failure != null) return Error(failure!);
    return Success(
      PrayerDay(
        date: DateTime(2026, 11, 10),
        city: 'الرياض',
        times: const <Prayer, String>{
          Prayer.fajr: '04:30',
          Prayer.dhuhr: '11:40',
          Prayer.asr: '15:00',
          Prayer.maghrib: '17:20',
          Prayer.isha: '18:50',
        },
      ),
    );
  }
}

void main() {
  group('PrayerTimesCubit', () {
    // 10:00 UTC is 13:00 in Riyadh on 10 November 2026. Tests move it, so
    // each one starts from it again.
    late DateTime clock;
    setUp(() => clock = DateTime.utc(2026, 11, 10, 10));

    test('loads once per Riyadh day and again when the day changes', () async {
      final _FakeRepository repository = _FakeRepository();
      final PrayerTimesCubit cubit = PrayerTimesCubit(
        PrayerTimesUseCase(repository),
        clock: () => clock,
      );
      addTearDown(cubit.close);

      await cubit.load('circle-1', 'Asia/Riyadh');
      await cubit.load('circle-1', 'Asia/Riyadh');
      expect(repository.reads, 1);
      expect(cubit.state.status, PrayerTimesStatus.ready);

      // 22:00 UTC is already 11 November in Riyadh.
      clock = DateTime.utc(2026, 11, 10, 22);
      await cubit.load('circle-1', 'Asia/Riyadh');
      expect(repository.reads, 2);
    });

    test('a patient in another zone keeps their own day', () async {
      final _FakeRepository repository = _FakeRepository();
      final PrayerTimesCubit cubit = PrayerTimesCubit(
        PrayerTimesUseCase(repository),
        clock: () => clock,
      );
      addTearDown(cubit.close);

      // 22:00 UTC on the 10th is 17:00 on the 10th in Toronto: the day the
      // fake answers with, so it is not read again.
      clock = DateTime.utc(2026, 11, 10, 22);
      await cubit.load('circle-1', 'America/Toronto');
      await cubit.load('circle-1', 'America/Toronto');
      expect(repository.reads, 1);
    });

    test('a day read at 23:59 is read again at 00:00 of the patient', () async {
      final _FakeRepository repository = _FakeRepository();
      final PrayerTimesCubit cubit = PrayerTimesCubit(
        PrayerTimesUseCase(repository),
        clock: () => clock,
      );
      addTearDown(cubit.close);

      // 20:59 UTC on the 10th is 23:59 in Riyadh.
      clock = DateTime.utc(2026, 11, 10, 20, 59);
      await cubit.load('circle-1', 'Asia/Riyadh');
      await cubit.load('circle-1', 'Asia/Riyadh');
      expect(repository.reads, 1);

      // One minute later it is 00:00 of the 11th there.
      clock = DateTime.utc(2026, 11, 10, 21);
      await cubit.load('circle-1', 'Asia/Riyadh');
      expect(repository.reads, 2);
    });

    test('a failed first read can be tried again', () async {
      final _FakeRepository repository = _FakeRepository()
        ..failure = const ServerFailure('error.unknown');
      final PrayerTimesCubit cubit = PrayerTimesCubit(
        PrayerTimesUseCase(repository),
        clock: () => clock,
      );
      addTearDown(cubit.close);

      await cubit.load('circle-1', 'Asia/Riyadh');
      expect(cubit.state.status, PrayerTimesStatus.failure);
      expect(cubit.state.messageKey, 'error.unknown');

      repository.failure = null;
      await cubit.reload();
      expect(cubit.state.status, PrayerTimesStatus.ready);
      expect(cubit.state.day, isNotNull);
    });

    test("a failed refresh keeps today's times", () async {
      final _FakeRepository repository = _FakeRepository();
      final PrayerTimesCubit cubit = PrayerTimesCubit(
        PrayerTimesUseCase(repository),
        clock: () => clock,
      );
      addTearDown(cubit.close);
      await cubit.load('circle-1', 'Asia/Riyadh');
      final PrayerDay shown = cubit.state.day!;

      repository.failure = const ServerFailure('error.unknown');
      await cubit.reload();

      expect(cubit.state.status, PrayerTimesStatus.ready);
      expect(cubit.state.day, shown);
    });

    test(
      "a failed refresh on a new day is a failure, not yesterday's times",
      () async {
        final _FakeRepository repository = _FakeRepository();
        final PrayerTimesCubit cubit = PrayerTimesCubit(
          PrayerTimesUseCase(repository),
          clock: () => clock,
        );
        addTearDown(cubit.close);
        await cubit.load('circle-1', 'Asia/Riyadh');

        // 22:00 UTC is already 11 November in Riyadh.
        clock = DateTime.utc(2026, 11, 10, 22);
        repository.failure = const ServerFailure('error.unknown');
        await cubit.reload();

        expect(cubit.state.status, PrayerTimesStatus.failure);
        expect(cubit.state.day, isNull);
      },
    );

    test("the next prayer is read on the patient's clock, with DST", () {
      // London on 26 October 2026, after summer time ended: 12:30 UTC is
      // 12:30 there, after Dhuhr and before Asr. With summer time (UTC+1)
      // it would be 13:30.
      final PrayerDay day = PrayerDay(
        date: DateTime(2026, 10, 26),
        city: 'لندن',
        timeZone: 'Europe/London',
        times: const <Prayer, String>{
          Prayer.fajr: '05:30',
          Prayer.dhuhr: '11:55',
          Prayer.asr: '13:15',
          Prayer.maghrib: '16:40',
          Prayer.isha: '18:15',
        },
      );
      expect(day.nextPrayer(DateTime.utc(2026, 10, 26, 12, 30)), Prayer.asr);
      expect(day.nextPrayer(DateTime.utc(2026, 10, 26, 11, 30)), Prayer.dhuhr);
    });
  });
}
