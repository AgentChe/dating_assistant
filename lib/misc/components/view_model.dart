import 'dart:async';

import 'package:flutter/foundation.dart';

/// База для ViewModel экранов (вместо связки RxActivityIndicator + ObservableRetrySingle).
///
/// - Состояние экрана — поля ViewModel; после изменения вызываем notifyListeners(),
///   экран перерисовывается через ListenableBuilder.
/// - Разовые события (переходы, закрытие) — поток [actions]: экран слушает его и навигирует.
/// - Запросы оборачиваем в [perform]: он ведёт [isLoading], а при ошибке через [tryAgain]
///   показывает ошибку и повторяет запрос, пока пользователь жмёт «Повторить».
abstract class ViewModel<Action> extends ChangeNotifier {
  final _actions = StreamController<Action>.broadcast();

  var _activeRequests = 0;

  var _isDisposed = false;

  /// Показывает ошибку и завершается `true`, если пользователь выбрал «Повторить». Задаёт экран.
  Future<bool> Function(Object error)? tryAgain;

  Stream<Action> get actions => _actions.stream;

  bool get isLoading => _activeRequests > 0;

  @protected
  void emit(Action action) {
    if (!_isDisposed) _actions.add(action);
  }

  /// Выполняет [request]; при ошибке спрашивает [tryAgain] и повторяет.
  /// Возвращает null, если пользователь отказался повторять.
  @protected
  Future<T?> perform<T>(Future<T> Function() request) async {
    while (true) {
      _changeActiveRequests(1);
      try {
        final result = await request();
        _changeActiveRequests(-1);
        return result;
      } catch (error) {
        _changeActiveRequests(-1);
        debugPrint('$runtimeType: $error');
        final retry = await tryAgain?.call(error) ?? false;
        if (!retry) return null;
      }
    }
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    tryAgain = null;
    _actions.close();
    super.dispose();
  }

  void _changeActiveRequests(int delta) {
    _activeRequests += delta;
    notifyListeners();
  }
}
