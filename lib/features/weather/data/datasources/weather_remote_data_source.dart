import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../../../core/errors/app_exception.dart';
import '../models/location_model.dart';
import '../models/weather_model.dart';

abstract class WeatherRemoteDataSource {
  Future<WeatherModel> fetchWeatherByCurrentLocation();

  Future<WeatherModel> fetchWeatherByCity(String city);

  Future<List<String>> fetchCitySuggestions(String query);
}

class WeatherRemoteDataSourceImpl implements WeatherRemoteDataSource {
  WeatherRemoteDataSourceImpl({required http.Client client}) : _client = client;

  final http.Client _client;

  @override
  Future<WeatherModel> fetchWeatherByCurrentLocation() async {
    final servicesEnabled = await Geolocator.isLocationServiceEnabled();
    if (!servicesEnabled) {
      throw const AppException('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const AppException('Location permission denied.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    final location = await _resolveCityFromCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    return _fetchForecast(
      latitude: location.latitude,
      longitude: location.longitude,
      cityName: location.cityName,
    );
  }

  @override
  Future<WeatherModel> fetchWeatherByCity(String city) async {
    final query = city.trim();
    if (query.isEmpty) {
      throw const AppException('Please enter a city name.');
    }

    final location = await _directGeocode(query);
    return _fetchForecast(
      latitude: location.latitude,
      longitude: location.longitude,
      cityName: location.cityName,
    );
  }

  @override
  Future<List<String>> fetchCitySuggestions(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return const [];
    }
    final uri = Uri.https(
      'geodb-free-service.wirefreethought.com',
      '/v1/geo/cities',
      {'namePrefix': normalized, 'limit': '8', 'sort': '-population'},
    );

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        return const [];
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final results = payload['data'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        return const [];
      }

      final suggestions = <String>{};
      for (final result in results) {
        final item = result as Map<String, dynamic>;
        final cityName = item['city'] as String?;
        if (cityName == null || cityName.isEmpty) {
          continue;
        }
        final countryCode = item['countryCode'] as String?;
        suggestions.add(
          countryCode == null ? cityName : '$cityName, $countryCode',
        );
      }

      return suggestions.toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<WeatherModel> _fetchForecast({
    required double latitude,
    required double longitude,
    required String cityName,
  }) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'timezone': 'auto',
      'forecast_days': '16',
      'current': 'temperature_2m,relative_humidity_2m,weather_code,is_day',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,relative_humidity_2m_mean',
    });

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw AppException('Weather request failed (${response.statusCode}).');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return WeatherModel.fromOpenMeteo(json: payload, cityName: cityName);
  }

  Future<LocationModel> _directGeocode(String city) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': city,
      'count': '1',
      'language': 'en',
      'format': 'json',
    });

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw AppException('City lookup failed (${response.statusCode}).');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final results = payload['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) {
      throw const AppException('City not found.');
    }

    final first = results.first as Map<String, dynamic>;
    final cityName = first['name'] as String? ?? city;
    final countryCode = first['country_code'] as String?;

    return LocationModel(
      latitude: _asDouble(first['latitude']),
      longitude: _asDouble(first['longitude']),
      cityName: countryCode == null ? cityName : '$cityName, $countryCode',
    );
  }

  Future<LocationModel> _resolveCityFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    final lat = latitude.toStringAsFixed(6);
    final lon = longitude.toStringAsFixed(6);
    final path = '/v1/geo/locations/+$lat+$lon/nearbyCities';
    final uri = Uri.https('geodb-free-service.wirefreethought.com', path, {
      'limit': '1',
      'radius': '50',
    });

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        return LocationModel(
          latitude: latitude,
          longitude: longitude,
          cityName: 'Current City',
        );
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final data = payload['data'] as List<dynamic>?;
      if (data == null || data.isEmpty) {
        return LocationModel(
          latitude: latitude,
          longitude: longitude,
          cityName: 'Current City',
        );
      }

      final first = data.first as Map<String, dynamic>;
      final cityName = first['city'] as String?;
      final countryCode = first['countryCode'] as String?;
      final resolvedName = (cityName == null || cityName.isEmpty)
          ? 'Current City'
          : countryCode == null
          ? cityName
          : '$cityName, $countryCode';

      return LocationModel(
        latitude: latitude,
        longitude: longitude,
        cityName: resolvedName,
      );
    } catch (_) {
      return LocationModel(
        latitude: latitude,
        longitude: longitude,
        cityName: 'Current City',
      );
    }
  }

  double _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return 0;
  }
}
