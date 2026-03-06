import '../../../../core/usecase/usecase.dart';
import '../repositories/weather_repository.dart';

class GetCitySuggestions extends UseCase<List<String>, CitySuggestionsParams> {
  GetCitySuggestions(this.repository);

  final WeatherRepository repository;

  @override
  Future<List<String>> call(CitySuggestionsParams params) {
    return repository.getCitySuggestions(params.query);
  }
}

class CitySuggestionsParams {
  const CitySuggestionsParams(this.query);

  final String query;
}
