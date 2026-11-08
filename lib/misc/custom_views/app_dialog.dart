import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/material.dart';

/// Окно подтверждения (modal-window из Figma): по центру на затемнении 60% — значок, заголовок,
/// пояснение, действие и отмена. Отмена всегда второстепенная; у необратимого действия значок и кнопка красные.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmTitle,
    required this.cancelTitle,
    this.isDestructive = false,
  });

  static const _red = Color(0xFFFF5757);

  /// Завершается true, если выбрали действие; отмена или нажатие мимо окна — false.
  static Future<bool> show(
    BuildContext context, {
    required String icon,
    required String title,
    required String message,
    required String confirmTitle,
    required String cancelTitle,
    bool isDestructive = false,
  }) async {
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: cancelTitle,
      barrierColor: const Color(0x99000000),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => AppDialog(
        icon: icon,
        title: title,
        message: message,
        confirmTitle: confirmTitle,
        cancelTitle: cancelTitle,
        isDestructive: isDestructive,
      ),
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: Tween(begin: 0.95, end: 1.0).animate(curved), child: child),
        );
      },
    );
    return confirmed ?? false;
  }

  final String icon;

  final String title;

  final String message;

  final String confirmTitle;

  final String cancelTitle;

  /// Type=Destructive: красный значок и кнопка действия.
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        // Material — стиль текста по умолчанию: без него у подписей жёлтое подчёркивание.
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: 320,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              color: Appearance.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Appearance.hairline),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Appearance.surfaceRaised),
                    child: SvgIcon(icon, color: isDestructive ? _red : Appearance.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Fonts.headline.copyWith(fontSize: 18, height: 22.68 / 18),
                ),
                const SizedBox(height: 6),
                Text(message, textAlign: TextAlign.center, style: Fonts.caption),
                const SizedBox(height: 16),
                if (isDestructive)
                  PrimaryButton.danger(title: confirmTitle, onPressed: () => Navigator.of(context).pop(true))
                else
                  PrimaryButton(title: confirmTitle, onPressed: () => Navigator.of(context).pop(true)),
                const SizedBox(height: 8),
                // В окне обе кнопки по 52, хотя у второстепенной в компоненте 48.
                SizedBox(
                  height: 52,
                  child: PrimaryButton.secondary(title: cancelTitle, onPressed: () => Navigator.of(context).pop(false)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
