import 'package:dating_assistant/misc/appearance.dart';
import 'package:flutter/painting.dart';

/// Текстовые стили из Figma, шрифт Plus Jakarta Sans (аналог Fonts.swift).
///
/// Межстрочный интервал делим поровну сверху и снизу, как в Figma (`leadingDistribution: even`).
abstract final class Fonts {
  static const family = 'PlusJakartaSans';

  /// 36/42 ExtraBold — заголовок приветствия.
  static const display = TextStyle(
    fontFamily: family,
    fontSize: 36,
    height: 42 / 36,
    fontWeight: FontWeight.w800,
    color: Appearance.white,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 28/34 ExtraBold — заголовки экранов.
  static const title = TextStyle(
    fontFamily: family,
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w800,
    color: Appearance.white,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 16/24 Regular — подзаголовки экранов.
  static const subtitle = TextStyle(
    fontFamily: family,
    fontSize: 16,
    height: 24 / 16,
    color: Appearance.grey,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 12/15 Medium — надзаголовки («About you»).
  static const eyebrow = TextStyle(
    fontFamily: family,
    fontSize: 12,
    height: 15 / 12,
    fontWeight: FontWeight.w500,
    color: Appearance.grey,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 16/22 SemiBold — заголовки карточек и вариантов ответа.
  static const headline = TextStyle(
    fontFamily: family,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
    color: Appearance.white,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 16/22 Regular — сообщения и поля ввода.
  static const body = TextStyle(
    fontFamily: family,
    fontSize: 16,
    height: 22 / 16,
    color: Appearance.white,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 14/20 Regular — описания в карточках.
  static const caption = TextStyle(
    fontFamily: family,
    fontSize: 14,
    height: 20 / 14,
    color: Appearance.grey,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 14/18 Medium — чипы и подписи полей.
  static const label = TextStyle(
    fontFamily: family,
    fontSize: 14,
    height: 18 / 14,
    fontWeight: FontWeight.w500,
    color: Appearance.white,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 16/20 Medium — кнопки.
  static const button = TextStyle(
    fontFamily: family,
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w500,
    color: Appearance.black,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 28/36 SemiBold — крупная фраза на пастельной карточке.
  static const phrase = TextStyle(
    fontFamily: family,
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w600,
    color: Appearance.black,
    leadingDistribution: TextLeadingDistribution.even,
  );
}
