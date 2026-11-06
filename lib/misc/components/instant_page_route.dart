import 'package:flutter/material.dart';

/// Экран появляется без анимации — под сканированием или формой, которые потом закрываются над ним,
/// — а уходит как обычный, со свайпом назад на iOS.
class InstantPageRoute<T> extends MaterialPageRoute<T> {
  InstantPageRoute({required super.builder});

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => super.transitionDuration;
}
