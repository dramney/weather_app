import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/weather_entity.dart';
import '../bloc/weather_bloc.dart';
import '../bloc/weather_event.dart';
import '../bloc/weather_state.dart';
import '../utils/responsive_layout.dart';
import '../utils/weather_icon_mapper.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  static const _backgroundTransitionDuration = Duration(milliseconds: 850);
  static const _contentTransitionDuration = Duration(milliseconds: 420);
  static const _searchErrorResizeDuration = Duration(milliseconds: 260);
  static const _searchErrorFadeDuration = Duration(milliseconds: 220);
  static const _suggestionsTransitionDuration = Duration(milliseconds: 240);
  static const _searchErrorColor = Color(0xFFFFEBEB);
  static const _retryButtonColor = Color(0xFF0D3B66);
  static const _chipTextColor = Color(0xFF0A2C52);
  static const _chipSelectedColor = Color(0xFF0A2C52);
  static const _chipBackgroundColor = Color(0xFFF3F7FF);
  static const _chipBorderColor = Color(0xFF2E4F7A);
  static const _chipSelectedBorderColor = Color(0xFF8EB8F0);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int _visibleDays = 8;
  String? _lastSyncedCity;
  bool _suggestionsVisible = false;

  @override
  void initState() {
    super.initState();
    context.read<WeatherBloc>().add(const WeatherByLocationRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearch() {
    _searchByQuery(_searchController.text);
  }

  void _searchByQuery(String rawQuery) {
    final typedCity = rawQuery.trim();
    if (typedCity.isEmpty) {
      return;
    }

    final normalizedQuery = _normalizeCityQuery(typedCity);
    if (normalizedQuery.isEmpty) {
      return;
    }

    _searchFocusNode.unfocus();
    setState(() {
      _suggestionsVisible = false;
    });
    context.read<WeatherBloc>().add(const CitySuggestionsRequested(''));
    context.read<WeatherBloc>().add(WeatherByCityRequested(normalizedQuery));
  }

  void _onQueryChanged(String value) {
    setState(() {
      _suggestionsVisible = value.trim().isNotEmpty;
    });
    context.read<WeatherBloc>().add(CitySuggestionsRequested(value));
  }

  void _onSuggestionTap(String city) {
    setState(() {
      _suggestionsVisible = false;
    });
    _searchController.text = city;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: city.length),
    );
    _searchByQuery(city);
  }

  void _onSearchFieldTap() {
    _searchController.clear();
    context.read<WeatherBloc>().add(const CitySuggestionsRequested(''));
    setState(() {
      _suggestionsVisible = true;
    });
  }

  String _normalizeCityQuery(String input) {
    final query = input.trim();
    if (query.isEmpty) {
      return '';
    }

    final commaIndex = query.indexOf(',');
    if (commaIndex == -1) {
      return query;
    }

    return query.substring(0, commaIndex).trim();
  }

  String? _searchErrorText(WeatherState state) {
    if (state.searchError != null) {
      return state.searchError;
    }
    if (state.weather != null) {
      return state.message;
    }
    return null;
  }

  String _contentKey({
    required WeatherState state,
    required WeatherEntity? weather,
    required bool keyboardOpen,
  }) {
    return '${state.status}-${weather?.cityName}-${weather?.currentTemperature}-$_visibleDays-$keyboardOpen';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<WeatherBloc, WeatherState>(
        listenWhen: (previous, current) =>
            previous.weather?.cityName != current.weather?.cityName &&
            current.weather != null,
        listener: (context, state) {
          final city = state.weather?.cityName;
          if (city == null || city == _lastSyncedCity) {
            return;
          }
          _lastSyncedCity = city;
          _searchController.text = city;
          _searchController.selection = TextSelection.fromPosition(
            TextPosition(offset: city.length),
          );
        },
        child: BlocBuilder<WeatherBloc, WeatherState>(
          builder: (context, state) {
            final weather = state.weather;
            final gradientColors = _gradientForWeather(weather);
            final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
            final searchError = _searchErrorText(state);
            final contentKey = _contentKey(
              state: state,
              weather: weather,
              keyboardOpen: keyboardOpen,
            );

            return AnimatedContainer(
              duration: _backgroundTransitionDuration,
              curve: Curves.easeInOutCubicEmphasized,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors,
                ),
              ),
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final config = responsiveConfigForWidth(
                      constraints.maxWidth,
                    );
                    final showSuggestions =
                        _suggestionsVisible && state.citySuggestions.isNotEmpty;

                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: config.maxContentWidth,
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                config.horizontalPadding,
                                12,
                                config.horizontalPadding,
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSearchField(config),
                                  _buildSearchError(config, searchError),
                                  SizedBox(height: config.isWide ? 24 : 16),
                                  Expanded(
                                    child: AnimatedSwitcher(
                                      duration: _contentTransitionDuration,
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      transitionBuilder: (child, animation) {
                                        final slide = Tween<Offset>(
                                          begin: const Offset(0, 0.03),
                                          end: Offset.zero,
                                        ).animate(animation);
                                        return FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                            position: slide,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: KeyedSubtree(
                                        key: ValueKey<String>(contentKey),
                                        child: _buildContent(
                                          state,
                                          config,
                                          keyboardOpen,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildSuggestionsOverlay(
                              config,
                              state,
                              showSuggestions,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchError(ResponsiveLayoutConfig config, String? searchError) {
    final hasError = searchError != null && searchError.isNotEmpty;
    return AnimatedSize(
      duration: _searchErrorResizeDuration,
      curve: Curves.easeOutCubic,
      child: AnimatedSwitcher(
        duration: _searchErrorFadeDuration,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: hasError
            ? Padding(
                key: ValueKey<String>(searchError),
                padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                child: Text(
                  searchError,
                  style: TextStyle(
                    color: _searchErrorColor,
                    fontSize: config.infoFontSize - 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : const SizedBox.shrink(key: ValueKey<String>('no-search-error')),
      ),
    );
  }

  Widget _buildSuggestionsOverlay(
    ResponsiveLayoutConfig config,
    WeatherState state,
    bool showSuggestions,
  ) {
    return Positioned(
      top: config.isWide ? 76 : 66,
      left: config.horizontalPadding,
      right: config.horizontalPadding,
      child: AnimatedSwitcher(
        duration: _suggestionsTransitionDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final offset = Tween<Offset>(
            begin: const Offset(0, -0.04),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
        child: showSuggestions
            ? KeyedSubtree(
                key: const ValueKey<String>('suggestions-visible'),
                child: _buildSuggestionsPanel(config, state),
              )
            : const SizedBox.shrink(
                key: ValueKey<String>('suggestions-hidden'),
              ),
      ),
    );
  }

  Widget _buildSearchField(ResponsiveLayoutConfig config) {
    final searchBorderRadius = _searchFieldBorderRadius(config);
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      onTap: _onSearchFieldTap,
      onChanged: _onQueryChanged,
      onSubmitted: (_) => _onSearch(),
      textInputAction: TextInputAction.search,
      style: TextStyle(color: Colors.white, fontSize: config.searchFontSize),
      decoration: InputDecoration(
        hintText: 'Input City.',
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: config.searchFontSize,
        ),
        contentPadding: _searchFieldContentPadding(config),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.18),
        suffixIcon: IconButton(
          onPressed: _onSearch,
          icon: Icon(
            Icons.search,
            color: Colors.white,
            size: config.isWide ? 30 : 24,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: searchBorderRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: searchBorderRadius,
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: searchBorderRadius,
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  EdgeInsets _searchFieldContentPadding(ResponsiveLayoutConfig config) {
    return EdgeInsets.symmetric(
      horizontal: 16,
      vertical: config.isWide ? 18 : 14,
    );
  }

  BorderRadius _searchFieldBorderRadius(ResponsiveLayoutConfig config) {
    return BorderRadius.circular(config.isWide ? 28 : 22);
  }

  Widget _buildSuggestionsPanel(
    ResponsiveLayoutConfig config,
    WeatherState state,
  ) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 240),
        decoration: BoxDecoration(
          color: const Color(0xFF31405E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: state.citySuggestions.length,
          separatorBuilder: (context, index) =>
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          itemBuilder: (context, index) {
            final city = state.citySuggestions[index];
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _onSuggestionTap(city),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Text(
                  city,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: config.forecastItemFontSize,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    WeatherState state,
    ResponsiveLayoutConfig config,
    bool keyboardOpen,
  ) {
    if (state.status == WeatherStatus.loading && state.weather == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (state.status == WeatherStatus.error && state.weather == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.message ?? 'Unable to load weather data.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: config.infoFontSize,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  context.read<WeatherBloc>().add(
                    const WeatherByLocationRequested(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _retryButtonColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(fontSize: config.isWide ? 20 : 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final weather = state.weather;
    if (weather == null) {
      return const SizedBox.shrink();
    }

    final visibleForecast = weather.forecast
        .take(_visibleDays)
        .toList(growable: false);
    final panelHeight = _forecastPanelHeight(config, _visibleDays);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactLayout =
            constraints.maxHeight < 340 || constraints.maxWidth < 230;

        if (compactLayout) {
          return SingleChildScrollView(
            physics: _weatherScrollPhysics(keyboardOpen),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentWeatherCard(weather, config),
                  const SizedBox(height: 14),
                  _buildForecastLengthToggle(config),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: panelHeight,
                    child: _buildForecastList(
                      visibleForecast,
                      config,
                      keyboardOpen,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentWeatherCard(weather, config),
            SizedBox(height: config.screenType == ScreenType.tablet ? 24 : 20),
            _buildForecastLengthToggle(config),
            const SizedBox(height: 12),
            Flexible(
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: panelHeight,
                  child: _buildForecastList(
                    visibleForecast,
                    config,
                    keyboardOpen,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentWeatherCard(
    WeatherEntity weather,
    ResponsiveLayoutConfig config,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          weather.cityName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: config.cityFontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: config.isWide ? 12 : 8),
        Icon(
          iconForWeatherCode(weather.currentWeatherCode),
          size: config.weatherIconSize * 0.72,
          color: Colors.white,
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '${_roundedTemperature(weather.currentTemperature)} C',
            style: TextStyle(
              color: Colors.white,
              fontSize: config.temperatureFontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(height: config.isWide ? 8 : 4),
        Text(
          'Max ${_roundedTemperature(weather.maxTemperature)} C  Min ${_roundedTemperature(weather.minTemperature)} C  Humidity ${weather.currentHumidity}%',
          style: TextStyle(
            color: Colors.white,
            fontSize: config.infoFontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildForecastLengthToggle(ResponsiveLayoutConfig config) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _buildDaysChip(config, days: 8),
        _buildDaysChip(config, days: 16),
      ],
    );
  }

  Widget _buildDaysChip(ResponsiveLayoutConfig config, {required int days}) {
    final isSelected = _visibleDays == days;
    return ChoiceChip(
      selected: isSelected,
      checkmarkColor: Colors.white,
      label: Text('$days days'),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : _chipTextColor,
        fontWeight: FontWeight.w600,
        fontSize: config.forecastItemFontSize - 1,
      ),
      backgroundColor: _chipBackgroundColor,
      selectedColor: _chipSelectedColor,
      side: BorderSide(
        color: isSelected ? _chipSelectedBorderColor : _chipBorderColor,
      ),
      onSelected: (_) {
        setState(() {
          _visibleDays = days;
        });
      },
    );
  }

  Widget _buildForecastList(
    List<DailyForecastEntity> forecast,
    ResponsiveLayoutConfig config,
    bool keyboardOpen,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final listWidth = constraints.maxWidth;
          final dayWidth = (listWidth * 0.24).clamp(56.0, 120.0);
          final iconSize = listWidth < 260
              ? 18.0
              : (config.isWide ? 24.0 : 22.0);
          final horizontalGap = listWidth < 260
              ? 8.0
              : (config.isWide ? 20.0 : 16.0);
          final humidityWidth = listWidth < 260 ? 40.0 : 48.0;

          return ListView.separated(
            padding: EdgeInsets.symmetric(
              vertical: config.isWide ? 20 : 14,
              horizontal: config.isWide ? 18 : 12,
            ),
            physics: _weatherScrollPhysics(keyboardOpen),
            itemCount: forecast.length,
            separatorBuilder: (context, index) =>
                Divider(color: Colors.white.withValues(alpha: 0.2), height: 14),
            itemBuilder: (context, index) {
              final day = forecast[index];
              return Row(
                children: [
                  SizedBox(
                    width: dayWidth,
                    child: Text(
                      DateFormat('EEE').format(day.date),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: config.forecastItemFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    iconForWeatherCode(day.weatherCode),
                    color: Colors.white,
                    size: iconSize,
                  ),
                  SizedBox(width: horizontalGap),
                  Expanded(
                    child: Text(
                      '${_roundedTemperature(day.temperature)} C',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: config.forecastItemFontSize,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: humidityWidth,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${day.humidity}%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: config.forecastItemFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Color> _gradientForWeather(WeatherEntity? weather) {
    if (weather == null) {
      return const [Color(0xFF0B132B), Color(0xFF1C2541), Color(0xFF3A506B)];
    }

    final isDay = weather.isDay;
    final weatherCode = weather.currentWeatherCode;

    final clear = weatherCode == 0;
    final cloudy =
        weatherCode == 1 ||
        weatherCode == 2 ||
        weatherCode == 3 ||
        weatherCode == 45 ||
        weatherCode == 48;
    final rainy =
        (weatherCode >= 51 && weatherCode <= 67) ||
        (weatherCode >= 80 && weatherCode <= 82);
    final snowy = weatherCode >= 71 && weatherCode <= 77;
    final storm = weatherCode >= 95 && weatherCode <= 99;

    if (isDay && clear) {
      return const [Color(0xFFFFD166), Color(0xFFF6B93B), Color(0xFFE58E26)];
    }
    if (!isDay && clear) {
      return const [Color(0xFF0B1026), Color(0xFF1E2A5A), Color(0xFF3949AB)];
    }
    if (cloudy && isDay) {
      return const [Color(0xFF7286A0), Color(0xFF5C6F88), Color(0xFF3F516D)];
    }
    if (cloudy && !isDay) {
      return const [Color(0xFF1A2333), Color(0xFF2C3A50), Color(0xFF374A63)];
    }
    if (rainy) {
      return const [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)];
    }
    if (snowy) {
      return const [Color(0xFF90AFC5), Color(0xFF6C8EA6), Color(0xFF4B6982)];
    }
    if (storm) {
      return const [Color(0xFF141E30), Color(0xFF243B55), Color(0xFF1A2238)];
    }

    return isDay
        ? const [Color(0xFF3B6AA0), Color(0xFF4D7FB3), Color(0xFF5A90C5)]
        : const [Color(0xFF0B132B), Color(0xFF1C2541), Color(0xFF3A506B)];
  }

  double _forecastPanelHeight(ResponsiveLayoutConfig config, int visibleDays) {
    final rowHeight = config.forecastItemFontSize + 18;
    final verticalPadding = config.isWide ? 40.0 : 28.0;
    final estimated = (visibleDays * rowHeight) + verticalPadding;

    final maxHeight = switch (config.screenType) {
      ScreenType.mobile => 360.0,
      ScreenType.tablet => 420.0,
      ScreenType.desktop => 500.0,
    };

    return estimated.clamp(170.0, maxHeight);
  }

  ScrollPhysics _weatherScrollPhysics(bool keyboardOpen) {
    return keyboardOpen
        ? const NeverScrollableScrollPhysics()
        : const ClampingScrollPhysics();
  }

  int _roundedTemperature(double value) {
    return value.round();
  }
}
