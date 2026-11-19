import 'dart:convert';
import 'dart:typed_data';

import 'package:app/core/network/medication_endpoints.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_circle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

/// A 1×1 PNG, so the image decodes like a real photo.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

/// Holds a photo for one medicine only.
class _OnePhoto extends OfflinePhotoRepository {
  @override
  Future<Uint8List?> load(String path) async =>
      path == MedicationEndpoints.medicationPhoto('circle-1', 'with-photo')
      ? _png
      : null;
}

Future<void> _pump(WidgetTester tester, String planId) => pumpArabic(
  tester,
  photos: _OnePhoto(),
  home: Scaffold(
    body: MedicationPhotoCircle(
      circleId: 'circle-1',
      planId: planId,
      size: 40,
      fallback: const Icon(Icons.medication),
    ),
  ),
);

void main() {
  setUpAll(initTestLocalization);

  group('MedicationPhotoCircle', () {
    testWidgets('shows the medicine photo when it has one', (
      WidgetTester tester,
    ) async {
      await _pump(tester, 'with-photo');

      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.medication), findsNothing);
    });

    testWidgets('a tap on the photo opens it full screen', (
      WidgetTester tester,
    ) async {
      await _pump(tester, 'with-photo');

      await tester.tap(find.byType(Image));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);
    });

    testWidgets('shows the pill while the medicine has no photo', (
      WidgetTester tester,
    ) async {
      await _pump(tester, 'without-photo');

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.medication), findsOneWidget);
    });
  });
}
