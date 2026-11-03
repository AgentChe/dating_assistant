import 'package:flutter/widgets.dart';

/// Переход с плавной сменой экрана — для смены «корня»: сплэш → онбординг → главный экран.
class FadePageRoute<T> extends PageRouteBuilder<T> {
  FadePageRoute({required WidgetBuilder builder})
    : super(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, _, _) => builder(context),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
      );
}
