import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import 'features/weather/data/datasources/weather_remote_data_source.dart';
import 'features/weather/data/repositories/weather_repository_impl.dart';
import 'features/weather/domain/usecases/get_city_suggestions.dart';
import 'features/weather/domain/usecases/get_weather_by_city.dart';
import 'features/weather/domain/usecases/get_weather_by_current_location.dart';
import 'features/weather/presentation/bloc/weather_bloc.dart';
import 'features/weather/presentation/pages/splash_screen.dart';

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    final client = http.Client();
    final remoteDataSource = WeatherRemoteDataSourceImpl(client: client);
    final repository = WeatherRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );
    final getCitySuggestions = GetCitySuggestions(repository);
    final getWeatherByCity = GetWeatherByCity(repository);
    final getWeatherByCurrentLocation = GetWeatherByCurrentLocation(repository);

    return BlocProvider(
      create: (_) => WeatherBloc(
        getCitySuggestions: getCitySuggestions,
        getWeatherByCity: getWeatherByCity,
        getWeatherByCurrentLocation: getWeatherByCurrentLocation,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Weather API App',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.transparent,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
