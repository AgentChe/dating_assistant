import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// Сообщение в чате с коучем (coach-message и user-message из Figma): коуч слева, пользователь справа,
/// острый угол снизу — со стороны того, кто написал.
class ChatBubble extends StatelessWidget {
  const ChatBubble.coach({super.key, required this.text}) : isFromUser = false;

  const ChatBubble.user({super.key, required this.text}) : isFromUser = true;

  /// Форма сообщения коуча — её же повторяет «печатает».
  static const coachRadius = BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(16),
    bottomRight: Radius.circular(16),
    bottomLeft: Radius.circular(4),
  );

  static const _userRadius = BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(16),
    bottomRight: Radius.circular(4),
    bottomLeft: Radius.circular(16),
  );

  static const _userColor = Color(0xFF242424);

  /// Не шире 308 из 396 в макете.
  static const _maxWidthFactor = 0.78;

  final String text;

  final bool isFromUser;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: isFromUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth * _maxWidthFactor),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isFromUser ? _userColor : Appearance.surfaceRaised,
              borderRadius: isFromUser ? _userRadius : coachRadius,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(text, style: Fonts.caption.copyWith(color: Appearance.white)),
            ),
          ),
        ),
      ),
    );
  }
}
