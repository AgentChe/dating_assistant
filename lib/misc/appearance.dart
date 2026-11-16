import 'package:flutter/painting.dart';

/// Цвета и градиенты из Figma (аналог Appearance.swift).
abstract final class Appearance {
  static const black = Color(0xFF000000);

  static const white = Color(0xFFFFFFFF);

  /// Второстепенный текст: подзаголовки, подписи.
  static const grey = Color(0xFF7D7C7C);

  /// Карточки и чипы.
  static const surface = Color(0xFF0C0C0C);

  /// Поля ввода, пузыри сообщений, треки прогресса.
  static const surfaceRaised = Color(0xFF151515);

  static const surfaceHigh = Color(0xFF1F1F1F);

  /// Обводка карточек — белый 4%.
  static const hairline = Color(0x0AFFFFFF);

  static const accent = Color(0xFFFF7D56);

  /// Опасные действия и ошибки: «Delete my data», Spicy.
  static const red = Color(0xFFFF5757);

  static const accentLight = Color(0xFFFF9B83);

  /// Пастельная заливка карточек: свайп-карточки, голос, план.
  static const pastelGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE9D5FF), Color(0xFFF5E1FF), Color(0xFFFFD6E7), Color(0xFFE0E7FF)],
    stops: [0, 0.25, 0.5, 1],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [accent, accentLight],
  );
}
