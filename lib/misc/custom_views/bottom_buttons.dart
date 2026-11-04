import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Кнопки внизу экрана: над home indicator, а при открытой клавиатуре — над ней.
class BottomButtons extends StatelessWidget {
  const BottomButtons({super.key, required this.buttons});

  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, math.max(MediaQuery.paddingOf(context).bottom + 3, 16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, button) in buttons.indexed) ...[if (index > 0) const SizedBox(height: 8), button],
        ],
      ),
    );
  }
}
