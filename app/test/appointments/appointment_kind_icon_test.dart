import 'package:app/core/constants/app_icons.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/appointments/presentation/widgets/appointment_kind_choices.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('A visit icon', () {
    test('says what the visit is for: no two kinds share one', () {
      final Set<int> glyphs = <int>{
        for (final AppointmentKind kind in AppointmentKind.values)
          appointmentKindIcon(kind).codePoint,
      };

      expect(glyphs, hasLength(AppointmentKind.values.length));
    });

    test('is drawn from the app icon font, not mirrored', () {
      for (final AppointmentKind kind in AppointmentKind.values) {
        final IconData icon = appointmentKindIcon(kind);
        expect(icon.fontFamily, 'PhosphorRegular', reason: kind.name);
        expect(icon.fontPackage, 'phosphor_flutter', reason: kind.name);
        expect(icon.matchTextDirection, isFalse, reason: kind.name);
      }
    });

    test('«أخرى» keeps the calendar', () {
      expect(
        appointmentKindIcon(AppointmentKind.other),
        ScheduleIcons.calendar,
      );
    });
  });
}
