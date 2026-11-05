import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/custom_views/pressable.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/cupertino.dart';

enum _Kind { accent, dark, secondary, plain }

/// Кнопка-пилюля из Figma (button/primary): оранжевая основная, чёрная, полупрозрачная или текстовая.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.title, required this.onPressed, this.isLoading = false})
    : _kind = _Kind.accent;

  /// Чёрная с жирным белым текстом — на пастельных карточках («Upload screenshot»).
  const PrimaryButton.dark({super.key, required this.title, required this.onPressed, this.isLoading = false})
    : _kind = _Kind.dark;

  /// Полупрозрачная белая с белым текстом («Manage subscription»).
  const PrimaryButton.secondary({super.key, required this.title, required this.onPressed, this.isLoading = false})
    : _kind = _Kind.secondary;

  /// Второстепенная кнопка без фона, с серым текстом («I’ll look around first»).
  const PrimaryButton.plain({super.key, required this.title, required this.onPressed, this.isLoading = false})
    : _kind = _Kind.plain;

  final String title;

  /// null — кнопка недоступна и полупрозрачна.
  final VoidCallback? onPressed;

  /// Спиннер вместо текста; кнопка не нажимается, но остаётся яркой.
  final bool isLoading;

  final _Kind _kind;

  @override
  Widget build(BuildContext context) {
    final (height, background, foreground) = switch (_kind) {
      _Kind.accent => (52.0, Appearance.accent, Appearance.black),
      _Kind.dark => (52.0, Appearance.black, Appearance.white),
      _Kind.secondary => (48.0, const Color(0x1FFFFFFF), Appearance.white),
      _Kind.plain => (44.0, null, Appearance.grey),
    };
    final style = Fonts.button.copyWith(
      color: foreground,
      fontWeight: _kind == _Kind.dark ? FontWeight.w700 : null,
    );
    return AnimatedOpacity(
      opacity: onPressed == null && !isLoading ? 0.4 : 1,
      duration: const Duration(milliseconds: 200),
      child: Pressable(
        onTap: isLoading ? null : onPressed,
        child: Container(
          width: double.infinity,
          height: height,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: ShapeDecoration(shape: const StadiumBorder(), color: background),
          child: isLoading ? CupertinoActivityIndicator(color: foreground, radius: 10) : Text(title, style: style),
        ),
      ),
    );
  }
}
