import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/usecase/usecase.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/usecases/get_city_suggestions.dart';
import '../../domain/usecases/get_weather_by_city.dart';
import '../../domain/usecases/get_weather_by_current_location.dart';
import 'weather_event.dart';
import 'weather_state.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  static const _fallbackCity = 'New York';
  static const _locationFallbackMessage =
      'Unable to access location. Showing fallback city.';
  static const _citySearchFailureMessage =
      'Something went wrong while searching for city weather.';
  static const _genericLoadFailureMessage = 'Failed to load weather data.';

  WeatherBloc({
    required GetCitySuggestions getCitySuggestions,
    required GetWeatherByCity getWeatherByCity,
    required GetWeatherByCurrentLocation getWeatherByCurrentLocation,
  }) : _getCitySuggestions = getCitySuggestions,
       _getWeatherByCity = getWeatherByCity,
       _getWeatherByCurrentLocation = getWeatherByCurrentLocation,
       super(const WeatherState()) {
    on<CitySuggestionsRequested>(_onCitySuggestionsRequested);
    on<WeatherByLocationRequested>(_onWeatherByLocationRequested);
    on<WeatherByCityRequested>(_onWeatherByCityRequested);
  }

  final GetCitySuggestions _getCitySuggestions;
  final GetWeatherByCity _getWeatherByCity;
  final GetWeatherByCurrentLocation _getWeatherByCurrentLocation;

  Future<void> _onCitySuggestionsRequested(
    CitySuggestionsRequested event,
    Emitter<WeatherState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(state.copyWith(citySuggestions: const [], clearSearchError: true));
      return;
    }

    try {
      final suggestions = await _getCitySuggestions(
        CitySuggestionsParams(query),
      );
      emit(
        state.copyWith(citySuggestions: suggestions, clearSearchError: true),
      );
    } catch (_) {
      emit(state.copyWith(citySuggestions: const [], clearSearchError: true));
    }
  }

  Future<void> _onWeatherByLocationRequested(
    WeatherByLocationRequested event,
    Emitter<WeatherState> emit,
  ) async {
    _emitLoading(emit);

    try {
      final weather = await _getWeatherByCurrentLocation(const NoParams());
      _emitLoadedWeather(emit, weather: weather);
    } on AppException catch (e) {
      await _loadFallbackWeather(emit, fallbackMessage: e.message);
    } catch (_) {
      await _loadFallbackWeather(
        emit,
        fallbackMessage: _locationFallbackMessage,
      );
    }
  }

  Future<void> _onWeatherByCityRequested(
    WeatherByCityRequested event,
    Emitter<WeatherState> emit,
  ) async {
    _emitLoading(emit);

    try {
      final weather = await _getWeatherByCity(CityParams(event.city));
      _emitLoadedWeather(emit, weather: weather);
    } on AppException catch (e) {
      _emitCitySearchError(emit, message: e.message);
    } catch (_) {
      _emitCitySearchError(emit, message: _citySearchFailureMessage);
    }
  }

  Future<void> _loadFallbackWeather(
    Emitter<WeatherState> emit, {
    required String fallbackMessage,
  }) async {
    try {
      final fallback = await _getWeatherByCity(const CityParams(_fallbackCity));
      _emitLoadedWeather(
        emit,
        weather: fallback,
        message: '$fallbackMessage Showing $_fallbackCity weather.',
      );
    } on AppException catch (e) {
      emit(
        state.copyWith(
          status: WeatherStatus.error,
          message: e.message,
          clearSearchError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: WeatherStatus.error,
          message: _genericLoadFailureMessage,
          clearSearchError: true,
        ),
      );
    }
  }

  void _emitLoading(Emitter<WeatherState> emit) {
    emit(
      state.copyWith(
        status: WeatherStatus.loading,
        clearMessage: true,
        clearSearchError: true,
      ),
    );
  }

  void _emitLoadedWeather(
    Emitter<WeatherState> emit, {
    required WeatherEntity weather,
    String? message,
  }) {
    emit(
      state.copyWith(
        status: WeatherStatus.loaded,
        weather: weather,
        message: message,
        clearMessage: message == null,
        clearSearchError: true,
        citySuggestions: const [],
      ),
    );
  }

  void _emitCitySearchError(
    Emitter<WeatherState> emit, {
    required String message,
  }) {
    final hasCachedWeather = state.weather != null;
    emit(
      state.copyWith(
        status: hasCachedWeather ? WeatherStatus.loaded : WeatherStatus.error,
        message: hasCachedWeather ? null : message,
        searchError: message,
        clearMessage: hasCachedWeather,
        citySuggestions: const [],
      ),
    );
  }
}
