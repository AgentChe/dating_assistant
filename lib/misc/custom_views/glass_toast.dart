import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/glass_panel.dart';
import 'package:dating_assistant/misc/custom_views/pressable.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// Короткая плашка под шапкой (toast из Figma): стекло, кружок с иконкой по типу, текст и, если нужно, действие
/// справа — «Undo». Скрывает её экран, примерно через 3 секунды.
class GlassToast extends StatelessWidget {
  /// Success: коралловый кружок с галочкой.
  const GlassToast.success({super.key, required this.message}) : _isSuccess = true, action = null, onAction = null;

  /// Info: белый 14% кружок с «i».
  const GlassToast.info({super.key, required this.message, this.action, this.onAction}) : _isSuccess = false;

  final String message;

  /// «Undo»; null — без действия.
  final String? action;

  final VoidCallback? onAction;

  final bool _isSuccess;

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    final style = Fonts.label.copyWith(height: 17.64 / 14);
    return GlassPanel(
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 18, 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isSuccess ? Appearance.accent : const Color(0x24FFFFFF),
              ),
              child: _isSuccess
                  ? const SvgIcon(AppIcons.check, size: 16, color: Appearance.black)
                  : const SvgIcon(AppIcons.info, size: 16, color: Appearance.white),
            ),
            const SizedBox(width: 10),
            Flexible(child: Text(message, style: style)),
            if (action != null) ...[
              const SizedBox(width: 10),
              Pressable(
                onTap: onAction,
                child: Text(
                  action,
                  style: style.copyWith(fontWeight: FontWeight.w600, color: Appearance.accent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
