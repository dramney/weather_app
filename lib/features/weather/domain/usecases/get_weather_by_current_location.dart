import '../../../../core/usecase/usecase.dart';
import '../entities/weather_entity.dart';
import '../repositories/weather_repository.dart';

class GetWeatherByCurrentLocation extends UseCase<WeatherEntity, NoParams> {
  GetWeatherByCurrentLocation(this.repository);

  final WeatherRepository repository;

  @override
  Future<WeatherEntity> call(NoParams params) {
    return repository.getWeatherByCurrentLocation();
  }
}
