import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/custom_views/pressable.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/cupertino.dart';

enum _Kind { accent, danger, dark, secondary, plain }

/// Кнопка-пилюля из Figma (button/primary): оранжевая основная, чёрная, полупрозрачная или текстовая.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.title, required this.onPressed, this.isLoading = false})
    : _kind = _Kind.accent;

  /// Красная — необратимое действие в окне подтверждения («Continue» перед удалением).
  const PrimaryButton.danger({super.key, required this.title, required this.onPressed, this.isLoading = false})
    : _kind = _Kind.danger;

  /// Чёрная с жирным белым текстом — на пастельных карточках («Upload screenshot»).
  const PrimaryButton.dark({super.key, required this.title, required this.onPressed, this.isLoading = false})
    : _kind = _Kind.dark;

  /// Полупрозрачная белая с белым текстом («Manage subscription»).
  const PrimaryButton.secondary({super.key, required this.title, required this.onPressed, this.isLoading = false})
    : _kind = _Kind.secondary;

  /// Второстепенная кнопка без фона, с серым текстом («I’ll look around first»).
  const PrimaryButton.plain({super.key, required this.title, required this.onPressed, this.isLoading = false})
    : _kind = _Kind.plain;

  /// Текст недоступной кнопки — белый 28%, как в State=Disabled компонента.
  static const _disabledForeground = Color(0x47FFFFFF);

  final String title;

  /// null — кнопка недоступна: приглушённый фон и текст, как в Figma.
  final VoidCallback? onPressed;

  /// Спиннер вместо текста; кнопка не нажимается, но остаётся яркой.
  final bool isLoading;

  final _Kind _kind;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null || isLoading;
    final (height, background, foreground) = switch ((_kind, isEnabled)) {
      (_Kind.accent, true) => (52.0, Appearance.accent, Appearance.black),
      (_Kind.accent, false) => (52.0, const Color(0x1FFFFFFF), _disabledForeground),
      (_Kind.danger, true) => (52.0, const Color(0xFFFF5757), Appearance.black),
      (_Kind.danger, false) => (52.0, const Color(0x1FFFFFFF), _disabledForeground),
      (_Kind.dark, true) => (52.0, Appearance.black, Appearance.white),
      (_Kind.dark, false) => (52.0, const Color(0x66000000), const Color(0x66FFFFFF)),
      (_Kind.secondary, true) => (48.0, const Color(0x1FFFFFFF), Appearance.white),
      (_Kind.secondary, false) => (48.0, const Color(0x0FFFFFFF), _disabledForeground),
      (_Kind.plain, true) => (44.0, null, Appearance.grey),
      (_Kind.plain, false) => (44.0, null, _disabledForeground),
    };
    final style = Fonts.button.copyWith(
      color: foreground,
      fontWeight: _kind == _Kind.dark ? FontWeight.w700 : null,
    );
    return Pressable(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: ShapeDecoration(shape: const StadiumBorder(), color: background),
        child: isLoading ? CupertinoActivityIndicator(color: foreground, radius: 10) : Text(title, style: style),
      ),
    );
  }
}
