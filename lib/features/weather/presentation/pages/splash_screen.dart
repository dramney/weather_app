import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/responsive_layout.dart';
import 'weather_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const WeatherPage()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF2C5364), Color(0xFF1A2980)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final config = responsiveConfigForWidth(constraints.maxWidth);
            final titleSize = switch (config.screenType) {
              ScreenType.mobile => 38.0,
              ScreenType.tablet => 52.0,
              ScreenType.desktop => 64.0,
            };
            final appLogoSize = switch (config.screenType) {
              ScreenType.mobile => 84.0,
              ScreenType.tablet => 104.0,
              ScreenType.desktop => 120.0,
            };
            final companySize = switch (config.screenType) {
              ScreenType.mobile => 20.0,
              ScreenType.tablet => 26.0,
              ScreenType.desktop => 32.0,
            };
            final companyLogoSize = switch (config.screenType) {
              ScreenType.mobile => 32.0,
              ScreenType.tablet => 40.0,
              ScreenType.desktop => 48.0,
            };

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: config.screenType == ScreenType.mobile
                      ? double.infinity
                      : 900,
                ),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 900),
                  tween: Tween<double>(begin: 0.86, end: 1),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAppLogo(appLogoSize),
                      SizedBox(height: config.isWide ? 24 : 18),
                      Text(
                        'Weather App',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleSize,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      SizedBox(height: config.isWide ? 30 : 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: companyLogoSize,
                            height: companyLogoSize,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(
                                config.isWide ? 12 : 8,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'K',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: companyLogoSize * 0.52,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'evych Solutions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: companySize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppLogo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD166), Color(0xFFF4A261), Color(0xFFE76F51)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66395B94),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.16,
            right: size * 0.18,
            child: Icon(
              Icons.wb_sunny_rounded,
              color: Colors.white.withValues(alpha: 0.9),
              size: size * 0.28,
            ),
          ),
          Icon(Icons.cloud_rounded, color: Colors.white, size: size * 0.56),
        ],
      ),
    );
  }
}
