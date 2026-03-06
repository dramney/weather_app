import '../../../../core/usecase/usecase.dart';
import '../entities/weather_entity.dart';
import '../repositories/weather_repository.dart';

class GetWeatherByCity extends UseCase<WeatherEntity, CityParams> {
  GetWeatherByCity(this.repository);

  final WeatherRepository repository;

  @override
  Future<WeatherEntity> call(CityParams params) {
    return repository.getWeatherByCity(params.city);
  }
}

class CityParams {
  const CityParams(this.city);

  final String city;
}
