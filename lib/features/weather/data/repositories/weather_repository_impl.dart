import '../../domain/entities/weather_entity.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/weather_remote_data_source.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  WeatherRepositoryImpl({required WeatherRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final WeatherRemoteDataSource _remoteDataSource;

  @override
  Future<WeatherEntity> getWeatherByCurrentLocation() {
    return _remoteDataSource.fetchWeatherByCurrentLocation();
  }

  @override
  Future<WeatherEntity> getWeatherByCity(String city) {
    return _remoteDataSource.fetchWeatherByCity(city);
  }

  @override
  Future<List<String>> getCitySuggestions(String query) {
    return _remoteDataSource.fetchCitySuggestions(query);
  }
}
