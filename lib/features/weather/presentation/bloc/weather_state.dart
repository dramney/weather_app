import 'package:equatable/equatable.dart';

import '../../domain/entities/weather_entity.dart';

enum WeatherStatus { initial, loading, loaded, error }

class WeatherState extends Equatable {
  const WeatherState({
    this.status = WeatherStatus.initial,
    this.weather,
    this.message,
    this.searchError,
    this.citySuggestions = const [],
  });

  final WeatherStatus status;
  final WeatherEntity? weather;
  final String? message;
  final String? searchError;
  final List<String> citySuggestions;

  WeatherState copyWith({
    WeatherStatus? status,
    WeatherEntity? weather,
    String? message,
    String? searchError,
    List<String>? citySuggestions,
    bool clearMessage = false,
    bool clearSearchError = false,
  }) {
    return WeatherState(
      status: status ?? this.status,
      weather: weather ?? this.weather,
      message: clearMessage ? null : (message ?? this.message),
      searchError: clearSearchError ? null : (searchError ?? this.searchError),
      citySuggestions: citySuggestions ?? this.citySuggestions,
    );
  }

  @override
  List<Object?> get props => [
    status,
    weather,
    message,
    searchError,
    citySuggestions,
  ];
}
