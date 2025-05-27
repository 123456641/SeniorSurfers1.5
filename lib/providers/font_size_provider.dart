import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontSizeProvider extends ChangeNotifier {
  static const String _fontSizeKey = 'app_font_size';
  static const double _defaultFontSize = 16.0;
  static const double _minFontSize = 10.0;
  static const double _maxFontSize = 30.0;

  double _fontSize = _defaultFontSize;
  bool _isLoading = true;

  double get fontSize => _fontSize;
  bool get isLoading => _isLoading;
  double get minFontSize => _minFontSize;
  double get maxFontSize => _maxFontSize;

  FontSizeProvider() {
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _fontSize = prefs.getDouble(_fontSizeKey) ?? _defaultFontSize;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading font size: $e');
      _fontSize = _defaultFontSize;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setFontSize(double newSize) async {
    final clampedSize = newSize.clamp(_minFontSize, _maxFontSize);
    if (_fontSize != clampedSize) {
      _fontSize = clampedSize;
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(_fontSizeKey, _fontSize);
      } catch (e) {
        print('Error saving font size: $e');
      }
    }
  }

  Future<void> resetToDefault() async {
    await setFontSize(_defaultFontSize);
  }

  // Get theme data with scaled font sizes
  ThemeData getScaledTheme(ThemeData baseTheme) {
    final scaleFactor = _fontSize / _defaultFontSize;

    return baseTheme.copyWith(
      textTheme: baseTheme.textTheme.copyWith(
        displayLarge: baseTheme.textTheme.displayLarge?.copyWith(
          fontSize:
              (baseTheme.textTheme.displayLarge?.fontSize ?? 32) * scaleFactor,
        ),
        displayMedium: baseTheme.textTheme.displayMedium?.copyWith(
          fontSize:
              (baseTheme.textTheme.displayMedium?.fontSize ?? 28) * scaleFactor,
        ),
        displaySmall: baseTheme.textTheme.displaySmall?.copyWith(
          fontSize:
              (baseTheme.textTheme.displaySmall?.fontSize ?? 24) * scaleFactor,
        ),
        headlineLarge: baseTheme.textTheme.headlineLarge?.copyWith(
          fontSize:
              (baseTheme.textTheme.headlineLarge?.fontSize ?? 22) * scaleFactor,
        ),
        headlineMedium: baseTheme.textTheme.headlineMedium?.copyWith(
          fontSize:
              (baseTheme.textTheme.headlineMedium?.fontSize ?? 20) *
              scaleFactor,
        ),
        headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(
          fontSize:
              (baseTheme.textTheme.headlineSmall?.fontSize ?? 18) * scaleFactor,
        ),
        titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
          fontSize:
              (baseTheme.textTheme.titleLarge?.fontSize ?? 16) * scaleFactor,
        ),
        titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
          fontSize:
              (baseTheme.textTheme.titleMedium?.fontSize ?? 14) * scaleFactor,
        ),
        titleSmall: baseTheme.textTheme.titleSmall?.copyWith(
          fontSize:
              (baseTheme.textTheme.titleSmall?.fontSize ?? 12) * scaleFactor,
        ),
        bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
          fontSize:
              (baseTheme.textTheme.bodyLarge?.fontSize ?? 16) * scaleFactor,
        ),
        bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
          fontSize:
              (baseTheme.textTheme.bodyMedium?.fontSize ?? 14) * scaleFactor,
        ),
        bodySmall: baseTheme.textTheme.bodySmall?.copyWith(
          fontSize:
              (baseTheme.textTheme.bodySmall?.fontSize ?? 12) * scaleFactor,
        ),
        labelLarge: baseTheme.textTheme.labelLarge?.copyWith(
          fontSize:
              (baseTheme.textTheme.labelLarge?.fontSize ?? 14) * scaleFactor,
        ),
        labelMedium: baseTheme.textTheme.labelMedium?.copyWith(
          fontSize:
              (baseTheme.textTheme.labelMedium?.fontSize ?? 12) * scaleFactor,
        ),
        labelSmall: baseTheme.textTheme.labelSmall?.copyWith(
          fontSize:
              (baseTheme.textTheme.labelSmall?.fontSize ?? 10) * scaleFactor,
        ),
      ),
    );
  }
}
