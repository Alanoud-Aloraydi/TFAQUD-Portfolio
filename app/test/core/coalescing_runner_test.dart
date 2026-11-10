import 'dart:async';

import 'package:app/core/utils/coalescing_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoalescingRunner', () {
    test('calls during a run fold into one more run right after', () async {
      final List<Completer<void>> gates = <Completer<void>>[];
      final CoalescingRunner runner = CoalescingRunner(() {
        final Completer<void> gate = Completer<void>();
        gates.add(gate);
        return gate.future;
      });

      final Future<void> first = runner.run();
      final Future<void> second = runner.run();
      final Future<void> third = runner.run();
      expect(third, same(second));
      expect(gates, hasLength(1));

      gates.first.complete();
      await first;
      await Future<void>.delayed(Duration.zero);
      // One more run, not two.
      expect(gates, hasLength(2));

      gates.last.complete();
      await Future<void>.delayed(Duration.zero);
      expect(gates, hasLength(2));
    });

    test(
      'dropPending forgets a run asked for during the current one',
      () async {
        int runs = 0;
        final Completer<void> gate = Completer<void>();
        final CoalescingRunner runner = CoalescingRunner(() {
          runs++;
          return gate.future;
        });

        final Future<void> first = runner.run();
        unawaited(runner.run());
        runner.dropPending();
        gate.complete();
        await first;
        await Future<void>.delayed(Duration.zero);

        expect(runs, 1);
      },
    );

    test('runs again once the last run is done', () async {
      int runs = 0;
      final CoalescingRunner runner = CoalescingRunner(() async => runs++);

      await runner.run();
      await runner.run();

      expect(runs, 2);
    });

    test('a call during a run ends only after the run that follows', () async {
      final List<Completer<void>> gates = <Completer<void>>[];
      final CoalescingRunner runner = CoalescingRunner(() {
        final Completer<void> gate = Completer<void>();
        gates.add(gate);
        return gate.future;
      });
      bool secondDone = false;

      unawaited(runner.run());
      unawaited(runner.run().then((_) => secondDone = true));
      gates.first.complete();
      await Future<void>.delayed(Duration.zero);
      expect(gates, hasLength(2));
      expect(secondDone, isFalse);

      gates.last.complete();
      await Future<void>.delayed(Duration.zero);
      expect(secondDone, isTrue);
    });

    test('a failed run still lets the one that follows run', () async {
      int runs = 0;
      final CoalescingRunner runner = CoalescingRunner(() async {
        runs++;
        if (runs == 1) throw StateError('offline');
      });

      final Future<void> first = runner.run();
      final Future<void> second = runner.run();

      await expectLater(first, throwsStateError);
      await second;
      expect(runs, 2);
    });
  });
}
