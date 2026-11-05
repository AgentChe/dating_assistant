import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// Плитка фичи из Figma (card/tile): 3D-иконка, стрелка, название и подпись.
class FeatureTile extends StatefulWidget {
  const FeatureTile({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});

  /// 3D-иконка из AppImages.
  final String icon;

  final String title;

  final String subtitle;

  final VoidCallback onTap;

  @override
  State<FeatureTile> createState() => _FeatureTileState();
}

class _FeatureTileState extends State<FeatureTile> {
  var _isPressed = false;

  @override
  Widget build(BuildContext context) {
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
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(widget.icon, width: 48, height: 48),
                    const Spacer(),
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Appearance.surfaceRaised),
                      child: const SvgIcon(AppIcons.chevronRight, size: 20, color: Appearance.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(widget.title, style: Fonts.headline.copyWith(height: 20 / 16)),
                const SizedBox(height: 4),
                Text(widget.subtitle, style: Fonts.caption.copyWith(height: 17.6 / 14)),
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
