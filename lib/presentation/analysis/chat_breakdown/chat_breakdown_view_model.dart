import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';

sealed class ChatBreakdownAction {
  const ChatBreakdownAction();
}

/// Тема из переписки — нужна первая фраза о ней.
final class OpenTopicLine extends ChatBreakdownAction {
  const OpenTopicLine(this.topic);

  final ChatTopic topic;
}

/// «Get the next message» — коуч с этой перепиской.
final class OpenCoach extends ChatBreakdownAction {
  const OpenCoach();
}

/// «Chat breakdown»: разбор переписки и следующий шаг.
class ChatBreakdownViewModel extends ViewModel<ChatBreakdownAction> {
  ChatBreakdownViewModel(this.breakdown);

  final ChatBreakdown breakdown;

  /// «Nika, 28» — или только имя, если возраст не виден.
  String get title {
    final (:name, :age) = breakdown.partner;
    return age == null ? name : '$name, $age';
  }

  void openTopic(ChatTopic topic) => emit(OpenTopicLine(topic));

  void getNextMessage() => emit(const OpenCoach());
}
