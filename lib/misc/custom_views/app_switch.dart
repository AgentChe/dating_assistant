import 'package:dating_assistant/misc/appearance.dart';
import 'package:flutter/widgets.dart';

/// Переключатель из Figma («switch», 51×31): включён — белая дорожка и чёрная ручка, выключен — дорожка
/// белая 14 % и белая ручка.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged, this.semanticLabel});

  final bool value;

  final ValueChanged<bool> onChanged;

  final String? semanticLabel;

  static const _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    // Свой узел: иначе VoiceOver сольёт переключатель с соседним текстом карточки.
    return Semantics(
      container: true,
      label: semanticLabel,
      toggled: value,
      onTap: () => onChanged(!value),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: _duration,
          curve: Curves.easeOut,
          width: 51,
          height: 31,
          padding: const EdgeInsets.all(2),
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            color: value ? Appearance.white : const Color(0x24FFFFFF),
          ),
          child: AnimatedAlign(
            duration: _duration,
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedContainer(
              duration: _duration,
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? Appearance.black : Appearance.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
