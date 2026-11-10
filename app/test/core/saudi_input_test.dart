import 'package:app/core/constants/saudi_cities.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SaudiCities', () {
    test(
      'the first seven cities are the cities of the design, in its order',
      () {
        expect(SaudiCities.all.take(7).toList(), <String>[
          'الرياض',
          'جدة',
          'مكة المكرمة',
          'المدينة المنورة',
          'الدمام',
          'بريدة',
          'أبها',
        ]);
      },
    );

    test('an empty search gives every city', () {
      expect(SaudiCities.search(''), SaudiCities.all);
      expect(SaudiCities.search('   '), SaudiCities.all);
    });

    test('a search finds the part of a name', () {
      expect(SaudiCities.search('رياض'), <String>['الرياض']);
    });

    test('another way of writing a letter finds the same city', () {
      // Alef without hamza for "أبها", and heh for the teh marbuta of "مكة".
      expect(SaudiCities.search('ابها'), <String>['أبها']);
      expect(SaudiCities.search('مكه'), <String>['مكة المكرمة']);
    });

    test('a name that is not in the list gives nothing', () {
      expect(SaudiCities.search('لندن'), isEmpty);
    });

    test('no city is written twice', () {
      expect(SaudiCities.all.toSet().length, SaudiCities.all.length);
    });
  });

  group('SaudiMobile', () {
    group('SaudiMobile.isValid', () {
      test('nine digits that start with 5 are valid', () {
        expect(SaudiMobile.isValid('512345678'), isTrue);
        expect(SaudiMobile.isValid('599999999'), isTrue);
      });

      test('anything else is not', () {
        expect(SaudiMobile.isValid(''), isFalse);
        expect(SaudiMobile.isValid('51234567'), isFalse);
        expect(SaudiMobile.isValid('5123456789'), isFalse);
        expect(SaudiMobile.isValid('412345678'), isFalse);
        expect(SaudiMobile.isValid('0512345678'), isFalse);
        expect(SaudiMobile.isValid('٥١٢٣٤٥٦٧٨'), isFalse);
        expect(SaudiMobile.isValid('5123 5678'), isFalse);
        expect(SaudiMobile.isValid('+966512345678'), isFalse);
      });
    });

    group('SaudiMobile numbers', () {
      test('the international number adds the country code', () {
        expect(SaudiMobile.international('501234567'), '+966501234567');
      });

      test('the national number drops it, and keeps any other text', () {
        expect(SaudiMobile.national('+966501234567'), '501234567');
        expect(SaudiMobile.national('501234567'), '501234567');
      });

      test('a number is grouped as it is typed', () {
        expect(SaudiMobile.group(''), '');
        expect(SaudiMobile.group('50'), '50');
        expect(SaudiMobile.group('501'), '50 1');
        expect(SaudiMobile.group('501234567'), '50 123 4567');
      });

      test('a number is shown with the country code and its groups', () {
        expect(SaudiMobile.display('+966501234567'), '+966 50 123 4567');
      });
    });
  });
}
