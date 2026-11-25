import 'package:app/app/services/weather/patient_weather.dart';
import 'package:flutter/cupertino.dart';

/// The icon of WeatherKit's condition, by day or night.
IconData weatherIcon(PatientWeather weather) {
  final bool day = weather.isDaylight;
  return switch (weather.condition) {
    'clear' ||
    'hot' => day ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_stars_fill,
    'mostlyClear' || 'partlyCloudy' =>
      day ? CupertinoIcons.cloud_sun_fill : CupertinoIcons.cloud_moon_fill,
    'cloudy' || 'mostlyCloudy' => CupertinoIcons.cloud_fill,
    'drizzle' ||
    'rain' ||
    'heavyRain' ||
    'sunShowers' ||
    'freezingDrizzle' ||
    'freezingRain' => CupertinoIcons.cloud_rain_fill,
    'thunderstorms' ||
    'isolatedThunderstorms' ||
    'scatteredThunderstorms' ||
    'strongStorms' ||
    'tropicalStorm' ||
    'hurricane' => CupertinoIcons.cloud_bolt_rain_fill,
    'snow' ||
    'heavySnow' ||
    'flurries' ||
    'sunFlurries' ||
    'blizzard' ||
    'blowingSnow' ||
    'sleet' ||
    'wintryMix' ||
    'hail' ||
    'frigid' => CupertinoIcons.snow,
    'foggy' || 'haze' || 'smoky' => CupertinoIcons.cloud_fog_fill,
    'windy' || 'breezy' || 'blowingDust' => CupertinoIcons.wind,
    _ => CupertinoIcons.thermometer,
  };
}
