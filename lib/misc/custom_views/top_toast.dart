import 'dart:async';

import 'package:dating_assistant/misc/custom_views/glass_toast.dart';
import 'package:flutter/material.dart';

/// Плашка сверху поверх всех экранов на несколько секунд — например, «Nothing was sent…» после «Not now».
/// Новая плашка заменяет прежнюю.
abstract final class TopToast {
  static OverlayEntry? _current;

  static void show(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    _current?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TopToast(
        message: message,
        duration: duration,
        onFinished: () {
          if (_current != entry) return;
          entry.remove();
          _current = null;
        },
      ),
    );
    _current = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }
}

class _TopToast extends StatefulWidget {
  const _TopToast({required this.message, required this.duration, required this.onFinished});

  final String message;

  final Duration duration;

  final VoidCallback onFinished;

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast> with SingleTickerProviderStateMixin {
  late final _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 250))..forward();

  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, () async {
      if (!mounted) return;
      await _fade.reverse();
      widget.onFinished();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Как плашки на экранах: под шапкой, на 75 ниже статус-бара.
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 75,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fade,
        // Без Material у текста в оверлее нет стиля по умолчанию.
        child: Material(
          type: MaterialType.transparency,
          child: Center(child: GlassToast.info(message: widget.message)),
        ),
      ),
    );
  }
}
