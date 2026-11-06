import 'dart:async';

/// События о бесплатных генерациях между экранами (аналог XxxMediator на PublishRelay из Swift-проектов).
class UsageMediator {
  final _changes = StreamController<void>.broadcast();

  /// Генерация потрачена — счётчик в профиле устарел.
  Stream<void> get changes => _changes.stream;

  void notifyGenerationUsed() => _changes.add(null);
}
