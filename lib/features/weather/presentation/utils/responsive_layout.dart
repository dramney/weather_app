enum ScreenType { mobile, tablet, desktop }

class ResponsiveLayoutConfig {
  const ResponsiveLayoutConfig({
    required this.screenType,
    required this.horizontalPadding,
    required this.maxContentWidth,
    required this.cityFontSize,
    required this.temperatureFontSize,
    required this.weatherIconSize,
    required this.infoFontSize,
    required this.forecastItemFontSize,
    required this.searchFontSize,
  });

  final ScreenType screenType;
  final double horizontalPadding;
  final double maxContentWidth;
  final double cityFontSize;
  final double temperatureFontSize;
  final double weatherIconSize;
  final double infoFontSize;
  final double forecastItemFontSize;
  final double searchFontSize;

  bool get isWide => screenType == ScreenType.desktop;
}

ResponsiveLayoutConfig responsiveConfigForWidth(double width) {
  if (width < 260) {
    return const ResponsiveLayoutConfig(
      screenType: ScreenType.mobile,
      horizontalPadding: 10,
      maxContentWidth: 320,
      cityFontSize: 30,
      temperatureFontSize: 52,
      weatherIconSize: 74,
      infoFontSize: 14,
      forecastItemFontSize: 13,
      searchFontSize: 14,
    );
  }

  if (width >= 900) {
    final maxContentWidth = width.clamp(980.0, 1400.0);
    return ResponsiveLayoutConfig(
      screenType: ScreenType.desktop,
      horizontalPadding: 32,
      maxContentWidth: maxContentWidth,
      cityFontSize: 44,
      temperatureFontSize: 78,
      weatherIconSize: 132,
      infoFontSize: 20,
      forecastItemFontSize: 19,
      searchFontSize: 19,
    );
  }

  if (width >= 600) {
    return const ResponsiveLayoutConfig(
      screenType: ScreenType.tablet,
      horizontalPadding: 24,
      maxContentWidth: 880,
      cityFontSize: 40,
      temperatureFontSize: 68,
      weatherIconSize: 112,
      infoFontSize: 19,
      forecastItemFontSize: 17,
      searchFontSize: 17,
    );
  }

  return const ResponsiveLayoutConfig(
    screenType: ScreenType.mobile,
    horizontalPadding: 16,
    maxContentWidth: 560,
    cityFontSize: 36,
    temperatureFontSize: 64,
    weatherIconSize: 98,
    infoFontSize: 17,
    forecastItemFontSize: 16,
    searchFontSize: 17,
  );
}
