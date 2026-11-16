import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// Строка карточки профиля: эмодзи, название, значение и шеврон («🙋 Gender — Woman ›»). Подсвечивается
/// при нажатии; линия под строкой — у всех, кроме последней в карточке.
class ProfileRow extends StatefulWidget {
  const ProfileRow({
    super.key,
    required this.emoji,
    required this.title,
    required this.value,
    required this.hasDivider,
    required this.onTap,
  });

  final String emoji;

  final String title;

  final String value;

  final bool hasDivider;

  final VoidCallback onTap;

  @override
  State<ProfileRow> createState() => _ProfileRowState();
}

class _ProfileRowState extends State<ProfileRow> {
  var _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final style = Fonts.body.copyWith(height: 20 / 16);
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _isPressed ? const Color(0x0AFFFFFF) : const Color(0x00FFFFFF),
              border: widget.hasDivider ? const Border(bottom: BorderSide(color: Color(0x14FFFFFF))) : null,
            ),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Text(widget.emoji, style: style.copyWith(fontSize: 20, height: 25.2 / 20)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.title, style: style)),
                const SizedBox(width: 12),
                Text(widget.value, style: style.copyWith(color: Appearance.grey)),
                const SizedBox(width: 12),
                const SvgIcon(AppIcons.chevronRight, size: 20, color: Appearance.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setPressed(bool isPressed) {
    if (_isPressed != isPressed) setState(() => _isPressed = isPressed);
  }
}
