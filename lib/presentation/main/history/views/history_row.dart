import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/cupertino.dart';

/// Запись истории (row/list из Figma): 3D-иконка, название, когда обновлялась и превью; нажатая — светлее.
class HistoryRow extends StatefulWidget {
  const HistoryRow({
    super.key,
    required this.icon,
    required this.title,
    required this.time,
    required this.preview,
    required this.isOpening,
    required this.onTap,
  });

  /// 3D-иконка из AppImages.
  final String icon;

  final String title;

  /// «4 min».
  final String time;

  final String preview;

  /// Запись загружается — вместо времени спиннер.
  final bool isOpening;

  final VoidCallback onTap;

  @override
  State<HistoryRow> createState() => _HistoryRowState();
}

class _HistoryRowState extends State<HistoryRow> {
  var _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final metaStyle = Fonts.caption.copyWith(height: 17.64 / 14);
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isPressed ? Appearance.surfaceHigh : Appearance.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Image.asset(widget.icon, width: 40, height: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Fonts.headline.copyWith(height: 20.16 / 16),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (widget.isOpening)
                            const SizedBox(
                              height: 18,
                              child: CupertinoActivityIndicator(radius: 7, color: Appearance.accent),
                            )
                          else
                            Text(widget.time, style: metaStyle.copyWith(color: Appearance.accent)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(widget.preview, maxLines: 1, overflow: TextOverflow.ellipsis, style: metaStyle),
                    ],
                  ),
                ),
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
