import 'package:dating_assistant/service/history/model/history_item.dart';

// Подписи записей истории из Figma; когда подключим локализацию, переедут в строки.

extension HistoryItemTitle on HistoryItem {
  /// «Nika, 28» у разбора; у разговора с коучем и первых фраз — название фичи.
  String get title => switch (kind) {
    HistoryKind.analysis => switch (partner) {
      null => 'Chat breakdown',
      (:final name, age: null) => name,
      (:final name, :final age) => '$name, $age',
    },
    HistoryKind.coachConversation => 'Dating advice',
    HistoryKind.openingLine => 'Opening line',
  };
}
