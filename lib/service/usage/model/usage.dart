/// Бесплатные генерации на этой неделе: ответы коуча, первые фразы и разборы чатов.
class Usage {
  const Usage({required this.used, required this.limit});

  factory Usage.fromJson(Map<String, dynamic> json) {
    final generations = json['generations'] as Map<String, dynamic>;
    return Usage(used: generations['used'] as int, limit: generations['limit'] as int);
  }

  final int used;

  /// Лимит бесплатного плана на неделю.
  final int limit;

  int get left => (limit - used).clamp(0, limit);
}
