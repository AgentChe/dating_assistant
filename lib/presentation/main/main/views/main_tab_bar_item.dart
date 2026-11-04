import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// Вкладка таб-бара (≈ TabItemView, компонент tab/item в Figma): у выбранной — подложка,
/// иконка и подпись в пастельном градиенте.
class MainTabBarItem extends StatefulWidget {
  const MainTabBarItem({
    super.key,
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String icon;

  final String title;

  final bool isSelected;

  final VoidCallback onTap;

  @override
  State<MainTabBarItem> createState() => _MainTabBarItemState();
}

class _MainTabBarItemState extends State<MainTabBarItem> {
  static const _duration = Duration(milliseconds: 200);

  var _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final background = switch ((widget.isSelected, _isPressed)) {
      (true, false) => const Color(0xFF242424),
      (true, true) => const Color(0xFF3D3D3D),
      (false, false) => const Color(0x00FFFFFF),
      (false, true) => const Color(0x24FFFFFF),
    };
    final icon = SvgIcon(widget.icon, color: Appearance.white);
    final title = Text(
      widget.title,
      maxLines: 1,
      style: Fonts.eyebrow.copyWith(color: Appearance.white),
    );

    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: widget.isSelected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          child: AnimatedContainer(
            duration: _duration,
            decoration: ShapeDecoration(shape: const StadiumBorder(), color: background),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: widget.isSelected ? 1 : 0),
              duration: _duration,
              builder: (context, selection, _) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Tint(selection: selection, child: icon),
                  const SizedBox(height: 2),
                  _Tint(selection: selection, child: title),
                ],
              ),
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

/// Перекрашивает белое содержимое: 0 — белое, 1 — пастельный градиент сверху вниз.
class _Tint extends StatelessWidget {
  const _Tint({required this.selection, required this.child});

  final double selection;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const pastel = Appearance.pastelGradient;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: pastel.begin,
        end: pastel.end,
        colors: [for (final color in pastel.colors) Color.lerp(Appearance.white, color, selection)!],
        stops: pastel.stops,
      ).createShader(bounds),
      child: child,
    );
  }
}
