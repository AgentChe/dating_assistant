import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/custom_views/pressable.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/cupertino.dart';

/// Кнопка-пилюля из Figma (button/primary): оранжевая основная или текстовая второстепенная.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.title, required this.onPressed, this.isLoading = false})
    : _isPlain = false;

  /// Второстепенная кнопка без фона, с серым текстом («I’ll look around first»).
  const PrimaryButton.plain({super.key, required this.title, required this.onPressed})
    : isLoading = false,
      _isPlain = true;

  final String title;

  /// null — кнопка недоступна и полупрозрачна.
  final VoidCallback? onPressed;

  /// Спиннер вместо текста; кнопка не нажимается, но остаётся яркой.
  final bool isLoading;

  final bool _isPlain;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: onPressed == null && !isLoading ? 0.4 : 1,
      duration: const Duration(milliseconds: 200),
      child: Pressable(
        onTap: isLoading ? null : onPressed,
        child: Container(
          width: double.infinity,
          height: _isPlain ? 44 : 52,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            color: _isPlain ? null : Appearance.accent,
          ),
          child: isLoading
              ? const CupertinoActivityIndicator(color: Appearance.black, radius: 10)
              : Text(title, style: Fonts.button.copyWith(color: _isPlain ? Appearance.grey : Appearance.black)),
        ),
      ),
    );
  }
}
