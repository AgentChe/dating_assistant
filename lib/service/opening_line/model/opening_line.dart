/// Что известно о мэтче: из анкеты на скриншоте или со слов пользователя («Type it out»).
class MatchDetails {
  const MatchDetails({this.name, this.age, this.message, this.interests});

  factory MatchDetails.fromJson(Map<String, dynamic> json) => MatchDetails(
    name: json['name'] as String?,
    age: json['age'] as int?,
    message: json['message'] as String?,
    interests: json['interests'] as String?,
  );

  final String? name;

  final int? age;

  /// Что мэтч написал — в анкете или первым сообщением.
  final String? message;

  /// Интересы или текст анкеты.
  final String? interests;

  bool get isEmpty => name == null && age == null && message == null && interests == null;

  Map<String, dynamic> toJson() => {
    'name': ?name,
    'age': ?age,
    'message': ?message,
    'interests': ?interests,
  };
}

/// Первая фраза для мэтча.
class OpeningLine {
  const OpeningLine({required this.id, required this.sessionId, required this.text, this.match});

  factory OpeningLine.fromJson(Map<String, dynamic> json) {
    final match = json['match'] as Map<String, dynamic>?;
    return OpeningLine(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      text: json['line'] as String,
      match: match == null ? null : MatchDetails.fromJson(match),
    );
  }

  final String id;

  /// Сессия фраз для одного мэтча: «Another one» просит следующую в ней же, в истории она одна запись.
  final String sessionId;

  final String text;

  /// Что сервер прочитал в анкете со скриншота: следующие фразы просим по нему, скриншот второй раз не шлём.
  /// Из истории сессия возвращается с тем, что известно о мэтче, — прочитано или введено.
  final MatchDetails? match;
}
