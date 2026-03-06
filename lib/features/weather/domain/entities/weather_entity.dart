import 'package:equatable/equatable.dart';

class WeatherEntity extends Equatable {
  const WeatherEntity({
    required this.cityName,
    required this.currentTemperature,
    required this.currentHumidity,
    required this.currentWeatherCode,
    required this.isDay,
    required this.observationTime,
    required this.maxTemperature,
    required this.minTemperature,
    required this.forecast,
  });

  final String cityName;
  final double currentTemperature;
  final int currentHumidity;
  final int currentWeatherCode;
  final bool isDay;
  final DateTime? observationTime;
  final double maxTemperature;
  final double minTemperature;
  final List<DailyForecastEntity> forecast;

  @override
  List<Object?> get props => [
    cityName,
    currentTemperature,
    currentHumidity,
    currentWeatherCode,
    isDay,
    observationTime,
    maxTemperature,
    minTemperature,
    forecast,
  ];
}

class DailyForecastEntity extends Equatable {
  const DailyForecastEntity({
    required this.date,
    required this.weatherCode,
    required this.temperature,
    required this.humidity,
  });

  final DateTime date;
  final int weatherCode;
  final double temperature;
  final int humidity;

  @override
  List<Object?> get props => [date, weatherCode, temperature, humidity];
}
