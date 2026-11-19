import 'package:app/features/circles/domain/circle_limit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CircleLimit', () {
    test('six circles reach the limit', () {
      expect(CircleLimit.reached(6, 0), isTrue);
      expect(CircleLimit.reached(5, 0), isFalse);
    });

    test('a sent request that still waits counts as a circle', () {
      expect(CircleLimit.reached(5, 1), isTrue);
      expect(CircleLimit.reached(4, 1), isFalse);
    });
  });
}
