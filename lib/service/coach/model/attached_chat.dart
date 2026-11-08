import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';

/// Переписка, о которой говорит коуч, — карточка «Chat attached»: с кем она и главный вывод.
class AttachedChat {
  const AttachedChat({required this.name, this.age, this.verdict});

  factory AttachedChat.fromJson(Map<String, dynamic> json) =>
      AttachedChat(name: json['name'] as String, age: json['age'] as int?, verdict: json['verdict'] as String?);

  /// Переписка из разбора («Get the next message»): вывод — тот же, что в начале разбора.
  factory AttachedChat.fromBreakdown(ChatBreakdown breakdown) {
    final (:name, :age) = breakdown.partner;
    final read = breakdown.read;
    return AttachedChat(name: name, age: age, verdict: '${read.verdict} — ${read.detail}');
  }

  final String name;

  /// Если виден в переписке.
  final int? age;

  /// «Nika is into this — and doing most of the work.».
  final String? verdict;
}
