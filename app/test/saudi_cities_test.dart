import 'package:app/features/circles/domain/saudi_cities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the first seven cities are the cities of the design, in its order', () {
    expect(SaudiCities.all.take(7).toList(), <String>[
      'الرياض',
      'جدة',
      'مكة المكرمة',
      'المدينة المنورة',
      'الدمام',
      'بريدة',
      'أبها',
    ]);
  });

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
}
