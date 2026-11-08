import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/pressable.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Строка истории, которая уезжает влево и открывает красную кнопку удаления (history — swipe delete из Figma).
/// Тянешь — открывается на [actionWidth], отпускаешь — встаёт открытой или закрытой. Открыта ли строка, решает экран:
/// так открытой остаётся только одна. VoiceOver удаляет через действие «Delete» — свайп ему недоступен.
class SwipeToDelete extends StatefulWidget {
  const SwipeToDelete({
    super.key,
    required this.isOpen,
    required this.onOpenChanged,
    required this.onDelete,
    required this.child,
  });

  /// На сколько строка уезжает влево.
  static const actionWidth = 88.0;

  final bool isOpen;

  final ValueChanged<bool> onOpenChanged;

  /// Нажали на корзину — экран спрашивает подтверждение.
  final VoidCallback onDelete;

  final Widget child;

  @override
  State<SwipeToDelete> createState() => _SwipeToDeleteState();
}

class _SwipeToDeleteState extends State<SwipeToDelete> with SingleTickerProviderStateMixin {
  /// 0 — строка на месте, 1 — уехала на [SwipeToDelete.actionWidth].
  late final _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: widget.isOpen ? 1 : 0,
  );

  @override
  void didUpdateWidget(SwipeToDelete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOpen != widget.isOpen) _settle(isOpen: widget.isOpen);
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Свайп — только пальцем; VoiceOver удаляет действием «Delete» у самой строки.
      excludeFromSemantics: true,
      onHorizontalDragUpdate: (details) => _reveal.value -= details.primaryDelta! / SwipeToDelete.actionWidth,
      onHorizontalDragEnd: (details) {
        // Быстрый взмах решает сам, медленное движение — по тому, открыта ли строка больше чем наполовину.
        final velocity = details.primaryVelocity ?? 0;
        final isOpen = velocity < -300 || (velocity <= 300 && _reveal.value > 0.5);
        _settle(isOpen: isOpen);
        if (isOpen != widget.isOpen) widget.onOpenChanged(isOpen);
      },
      child: Stack(
        children: [
          // Кнопка лежит под строкой справа и видна, когда строка уезжает.
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: SwipeToDelete.actionWidth,
            child: ExcludeSemantics(
              excluding: !widget.isOpen,
              child: Center(
                // Своим узлом: иначе подпись «Delete» сливается с соседней строкой.
                child: Semantics(
                  container: true,
                  child: Pressable(
                    onTap: widget.onDelete,
                    semanticLabel: 'Delete',
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF5757)),
                      child: const SvgIcon(AppIcons.trash, size: 20, color: Appearance.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _reveal,
            builder: (context, child) => Transform.translate(
              offset: Offset(-SwipeToDelete.actionWidth * _reveal.value, 0),
              child: child,
            ),
            // Действие в том же узле, что и строка, — VoiceOver предлагает его прямо на ней.
            child: MergeSemantics(
              child: Semantics(
                customSemanticsActions: {const CustomSemanticsAction(label: 'Delete'): widget.onDelete},
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _settle({required bool isOpen}) => _reveal.animateTo(isOpen ? 1 : 0, curve: Curves.easeOut);
}
