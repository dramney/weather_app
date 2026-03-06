import 'package:equatable/equatable.dart';

abstract class WeatherEvent extends Equatable {
  const WeatherEvent();

  @override
  List<Object?> get props => [];
}

class WeatherByLocationRequested extends WeatherEvent {
  const WeatherByLocationRequested();
}

class WeatherByCityRequested extends WeatherEvent {
  const WeatherByCityRequested(this.city);

  final String city;

  @override
  List<Object?> get props => [city];
}

class CitySuggestionsRequested extends WeatherEvent {
  const CitySuggestionsRequested(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}
