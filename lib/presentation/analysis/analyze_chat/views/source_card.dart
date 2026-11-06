import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// Откуда взять переписку: 3D-иконка, название, подпись и стрелка; справа сверху — украшение.
class SourceCard extends StatefulWidget {
  const SourceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.decoration,
  });

  /// 3D-иконка из AppImages.
  final String icon;

  final String title;

  final String subtitle;

  final VoidCallback onTap;

  /// Картинка под содержимым, прижатая к правому верхнему углу; карточка её обрезает.
  final Widget? decoration;

  @override
  State<SourceCard> createState() => _SourceCardState();
}

class _SourceCardState extends State<SourceCard> {
  var _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final decoration = widget.decoration;
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
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _isPressed ? Appearance.surfaceHigh : Appearance.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                if (decoration != null) Positioned(top: 0, right: 0, child: decoration),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(widget.icon, width: 48, height: 48),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.title, style: Fonts.headline.copyWith(fontSize: 18, height: 22.7 / 18)),
                                const SizedBox(height: 4),
                                Text(
                                  widget.subtitle,
                                  style: Fonts.subtitle.copyWith(height: 20 / 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Appearance.surfaceRaised),
                            child: const SvgIcon(AppIcons.chevronRight, size: 20, color: Appearance.white),
                          ),
                        ],
                      ),
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
