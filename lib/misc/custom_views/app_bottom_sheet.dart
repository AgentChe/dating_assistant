import 'dart:math' as math;

import 'package:dating_assistant/misc/appearance.dart';
import 'package:flutter/material.dart';

/// Шторка из Figma (bottom-sheet): тёмная панель со скруглением сверху и «ручкой».
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({super.key, required this.children});

  /// Блоки шторки сверху вниз, между ними 20.
  final List<Widget> children;

  /// Показывает шторку поверх таб-бара с затемнением 60%, как в Figma.
  static Future<T?> show<T>(BuildContext context, {required WidgetBuilder builder}) => showModalBottomSheet<T>(
    context: context,
    builder: builder,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x99000000),
    elevation: 0,
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Appearance.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.fromBorderSide(BorderSide(color: Color(0x14FFFFFF))),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, math.max(MediaQuery.paddingOf(context).bottom + 2, 16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: const Color(0x3DFFFFFF), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            for (final child in children) ...[const SizedBox(height: 20), child],
          ],
        ),
      ),
    );
  }
}
