import 'dart:ui' show ImageFilter;

import 'package:dating_assistant/misc/custom_views/screen_header.dart';
import 'package:flutter/widgets.dart';

/// Шапка поверх прокручиваемого контента (top-bar из Figma): затемнение с размытием, «назад» и заголовок.
/// Под шапкой может быть ещё блок [bottom] — например, карточка «Chat attached» у коуча.
class BlurredTopBar extends StatelessWidget {
  const BlurredTopBar({super.key, required this.title, required this.onBack, this.bottom});

  /// Высота без отступа сверху и без [bottom]: 11 + шапка 48 + 12.
  static const height = 71.0;

  final String title;

  final VoidCallback onBack;

  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final bottom = this.bottom;
    return Stack(
      children: [
        // Размытие кончается до нижних 12: иначе оно подтягивает в шапку цвет карточки под ней,
        // и по краю видна светлая полоса. Ниже остаётся только затемнение.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 12,
          child: ClipRect(
            child: BackdropFilter(filter: _blur, child: const SizedBox.expand()),
          ),
        ),
        DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xE6000000), Color(0xB8000000), Color(0x00000000)],
              stops: [0, 0.7, 1],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 11, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(title: title, onBack: onBack),
                if (bottom != null) ...[const SizedBox(height: 12), bottom],
              ],
            ),
          ),
        ),
      ],
    );
  }

  static final _blur = ImageFilter.blur(sigmaX: 8, sigmaY: 8);
}
