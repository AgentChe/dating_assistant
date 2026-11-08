import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/pressable.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// Тон баннера из Figma: системное состояние (нет сети), лимит или ошибка.
enum BannerTone { neutral, accent, error }

/// Постоянный баннер под шапкой (banner из Figma): значок по тону, заголовок, пояснение и действие справа.
/// На экране — не больше одного.
class InlineBanner extends StatelessWidget {
  const InlineBanner({
    super.key,
    required this.tone,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });

  static const _red = Color(0xFFFF5757);

  final BannerTone tone;

  final String title;

  final String message;

  /// «Retry»; null — без действия.
  final String? action;

  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    final (icon, iconColor, border) = switch (tone) {
      BannerTone.neutral => (AppIcons.wifiOff, Appearance.white, Appearance.hairline),
      BannerTone.accent => (AppIcons.sparkles, Appearance.accent, Appearance.hairline),
      BannerTone.error => (AppIcons.alertCircle, _red, const Color(0x66FF5757)),
    };
    final textStyle = Fonts.caption.copyWith(height: 17.64 / 14);
    final titleStyle = textStyle.copyWith(fontWeight: FontWeight.w600, color: Appearance.white);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Appearance.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgIcon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyle),
                const SizedBox(height: 2),
                Text(message, style: textStyle),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 12),
            Pressable(
              onTap: onAction,
              child: Text(
                action,
                // У ошибки действие белое, чтобы не спорить с красным значком.
                style: titleStyle.copyWith(color: tone == BannerTone.error ? Appearance.white : Appearance.accent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
