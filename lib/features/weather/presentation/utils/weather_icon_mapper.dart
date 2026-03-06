import 'package:flutter/material.dart';

IconData iconForWeatherCode(int weatherCode) {
  if (weatherCode == 0) {
    return Icons.wb_sunny_rounded;
  }
  if (weatherCode == 1 || weatherCode == 2) {
    return Icons.wb_cloudy_rounded;
  }
  if (weatherCode == 3 || weatherCode == 45 || weatherCode == 48) {
    return Icons.cloud_rounded;
  }
  if (weatherCode >= 51 && weatherCode <= 67) {
    return Icons.grain_rounded;
  }
  if (weatherCode >= 71 && weatherCode <= 77) {
    return Icons.ac_unit_rounded;
  }
  if ((weatherCode >= 80 && weatherCode <= 82) ||
      (weatherCode >= 95 && weatherCode <= 99)) {
    return Icons.thunderstorm_rounded;
  }
  return Icons.cloud_queue_rounded;
}
