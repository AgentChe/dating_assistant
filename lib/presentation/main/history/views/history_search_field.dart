import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/glass_panel.dart';
import 'package:dating_assistant/misc/custom_views/pressable.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/material.dart';

/// Поиск по истории (input из Figma): стеклянное поле с лупой; с текстом — крестик, чтобы стереть.
class HistorySearchField extends StatefulWidget {
  const HistorySearchField({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<HistorySearchField> createState() => _HistorySearchFieldState();
}

class _HistorySearchFieldState extends State<HistorySearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Без межбуквенного 0.5 из стиля bodyLarge, который TextField берёт из темы.
    final style = Fonts.body.copyWith(height: 20.16 / 16, letterSpacing: 0);
    return GlassPanel(
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: SvgIcon(AppIcons.search, color: Appearance.grey),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (text) {
                setState(() {});
                widget.onChanged(text);
              },
              textInputAction: TextInputAction.search,
              keyboardAppearance: Brightness.dark,
              style: style,
              cursorColor: Appearance.accent,
              cursorWidth: 2,
              cursorHeight: 20,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search conversations',
                hintStyle: style.copyWith(color: Appearance.grey),
                contentPadding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            Pressable(
              onTap: _clear,
              semanticLabel: 'Clear search',
              child: const Padding(
                padding: EdgeInsets.fromLTRB(0, 16, 16, 16),
                child: SvgIcon(AppIcons.close, size: 20, color: Appearance.grey),
              ),
            ),
        ],
      ),
    );
  }

  void _clear() {
    _controller.clear();
    setState(() {});
    widget.onChanged('');
  }
}
