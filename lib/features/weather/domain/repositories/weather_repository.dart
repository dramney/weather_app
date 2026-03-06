import '../entities/weather_entity.dart';

abstract class WeatherRepository {
  Future<WeatherEntity> getWeatherByCurrentLocation();

  Future<WeatherEntity> getWeatherByCity(String city);

  Future<List<String>> getCitySuggestions(String query);
}
