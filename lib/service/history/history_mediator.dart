import 'dart:async';

/// События об истории между экранами (аналог XxxMediator на PublishRelay из Swift-проектов).
class HistoryMediator {
  final _changes = StreamController<void>.broadcast();

  /// В истории что-то сохранили — список во вкладке History устарел.
  Stream<void> get changes => _changes.stream;

  void notifyChanged() => _changes.add(null);
}
