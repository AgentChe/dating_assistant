import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Есть ли у устройства сеть (аналог Reachability из Swift-проектов).
///
/// connectivity_plus видит только Wi-Fi, сотовую связь и прочие интерфейсы, а не то, отвечает ли сервер:
/// «офлайн» — когда интерфейсов нет совсем. Если плагин не ответил, считаем, что сеть есть,
/// — пусть решает запрос.
class ConnectivityManager {
  ConnectivityManager({Connectivity? connectivity}) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// true — сеть появилась, false — пропала.
  Stream<bool> get onlineChanges => _connectivity.onConnectivityChanged.map(_isOnline).handleError((Object error) {
    debugPrint('ConnectivityManager: cannot follow the connection: $error');
  });

  Future<bool> checkOnline() async {
    try {
      return _isOnline(await _connectivity.checkConnectivity());
    } catch (error) {
      debugPrint('ConnectivityManager: cannot check the connection: $error');
      return true;
    }
  }

  static bool _isOnline(List<ConnectivityResult> results) => results.any((result) => result != ConnectivityResult.none);
}
