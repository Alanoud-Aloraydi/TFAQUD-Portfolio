import 'package:app/core/services/weather/patient_weather.dart';
import 'package:app/features/home/presentation/widgets/today_weather.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _answer({String condition = 'clear'}) => <String, dynamic>{
  'temperature': 23.6,
  'condition': condition,
  'is_daylight': true,
  'mark_light': 'https://weather.example/light.png',
  'mark_dark': 'https://weather.example/dark.png',
  'legal_page': 'https://weather.example/legal',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PatientWeather', () {
    test('reads the iOS answer, the degrees rounded', () {
      final PatientWeather? weather = PatientWeather.fromMap(_answer());

      expect(weather?.degrees, 24);
      expect(weather?.condition, 'clear');
      expect(weather?.legalPage, 'https://weather.example/legal');
    });

    test('an answer it cannot read is no weather', () {
      expect(PatientWeather.fromMap(null), isNull);
      expect(
        PatientWeather.fromMap(<String, dynamic>{'temperature': 'hot'}),
        isNull,
      );
    });

    test('a condition has an icon, by day or night', () {
      final PatientWeather day = PatientWeather.fromMap(_answer())!;
      final PatientWeather rain = PatientWeather.fromMap(
        _answer(condition: 'heavyRain'),
      )!;

      expect(weatherIcon(day), CupertinoIcons.sun_max_fill);
      expect(weatherIcon(rain), CupertinoIcons.cloud_rain_fill);
    });
  });

  group('AppleWeather', () {
    late List<MethodCall> calls;
    DateTime now = DateTime(2026, 11, 13, 9);

    setUp(() {
      calls = <MethodCall>[];
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(AppleWeather.channel, (call) async {
            calls.add(call);
            return _answer();
          });
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(AppleWeather.channel, null);
    });

    test('asks once for a place until the reading is old', () async {
      final AppleWeather weather = AppleWeather(clock: () => now);

      final PatientWeather? first = await weather.now(26.3592, 43.9818);
      await weather.now(26.3593, 43.9817);
      now = now.add(AppleWeather.maxAge);
      await weather.now(26.3592, 43.9818);

      expect(first?.degrees, 24);
      expect(calls, hasLength(2));
      expect(calls.first.arguments, <String, dynamic>{
        'latitude': 26.3592,
        'longitude': 43.9818,
      });
    });
  });
}
