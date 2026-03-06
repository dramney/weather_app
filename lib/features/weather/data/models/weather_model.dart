// ignore_for_file: use_super_parameters

import '../../domain/entities/weather_entity.dart';

class WeatherModel extends WeatherEntity {
  const WeatherModel({
    required String cityName,
    required double currentTemperature,
    required int currentHumidity,
    required int currentWeatherCode,
    required bool isDay,
    required DateTime? observationTime,
    required double maxTemperature,
    required double minTemperature,
    required List<DailyForecastEntity> forecast,
  }) : super(
         cityName: cityName,
         currentTemperature: currentTemperature,
         currentHumidity: currentHumidity,
         currentWeatherCode: currentWeatherCode,
         isDay: isDay,
         observationTime: observationTime,
         maxTemperature: maxTemperature,
         minTemperature: minTemperature,
         forecast: forecast,
       );

  factory WeatherModel.fromOpenMeteo({
    required Map<String, dynamic> json,
    required String cityName,
  }) {
    final current = json['current'] as Map<String, dynamic>?;
    final daily = json['daily'] as Map<String, dynamic>?;

    if (current == null || daily == null) {
      throw const FormatException('Unexpected weather response format.');
    }

    final dates = (daily['time'] as List<dynamic>).cast<String>();
    final weatherCodes = (daily['weather_code'] as List<dynamic>).cast<num>();
    final maxTemperatures = (daily['temperature_2m_max'] as List<dynamic>)
        .cast<num>();
    final minTemperatures = (daily['temperature_2m_min'] as List<dynamic>)
        .cast<num>();
    final humidities = (daily['relative_humidity_2m_mean'] as List<dynamic>)
        .cast<num>();

    if (dates.isEmpty ||
        weatherCodes.isEmpty ||
        maxTemperatures.isEmpty ||
        minTemperatures.isEmpty ||
        humidities.isEmpty) {
      throw const FormatException('Incomplete daily forecast data.');
    }

    final forecast = <DailyForecastEntity>[];
    final maxItems = dates.length >= 16 ? 16 : dates.length;

    for (var i = 0; i < maxItems; i++) {
      forecast.add(
        DailyForecastEntity(
          date: DateTime.parse(dates[i]),
          weatherCode: weatherCodes[i].toInt(),
          temperature: maxTemperatures[i].toDouble(),
          humidity: humidities[i].round(),
        ),
      );
    }

    return WeatherModel(
      cityName: cityName,
      currentTemperature: (current['temperature_2m'] as num).toDouble(),
      currentHumidity: (current['relative_humidity_2m'] as num).round(),
      currentWeatherCode: (current['weather_code'] as num).toInt(),
      isDay: (current['is_day'] as num?)?.toInt() == 1,
      observationTime: DateTime.tryParse(current['time'] as String? ?? ''),
      maxTemperature: maxTemperatures.first.toDouble(),
      minTemperature: minTemperatures.first.toDouble(),
      forecast: forecast,
    );
  }
}
