import 'package:flutter/widgets.dart';

/// Нажимаемый элемент: на нажатие слегка уменьшается, как кнопки в iOS.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.onTap, required this.child, this.semanticLabel});

  final VoidCallback? onTap;

  final Widget child;

  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  var _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: isEnabled ? (_) => _setPressed(true) : null,
        onTapUp: isEnabled ? (_) => _setPressed(false) : null,
        onTapCancel: isEnabled ? () => _setPressed(false) : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          child: widget.child,
        ),
      ),
    );
  }

  void _setPressed(bool isPressed) {
    if (_isPressed != isPressed) setState(() => _isPressed = isPressed);
  }
}
