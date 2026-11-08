import 'dart:async';

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';

/// Сеть без плагина: состояние задаёт тест, [change] сообщает о переменах, как система.
class FakeConnectivity extends ConnectivityPlatform {
  FakeConnectivity({bool isOnline = true}) : _results = _resultsFor(isOnline);

  List<ConnectivityResult> _results;

  final _changes = StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _results;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _changes.stream;

  void change({required bool isOnline}) {
    _results = _resultsFor(isOnline);
    _changes.add(_results);
  }

  static List<ConnectivityResult> _resultsFor(bool isOnline) =>
      isOnline ? const [ConnectivityResult.wifi] : const [ConnectivityResult.none];
}
