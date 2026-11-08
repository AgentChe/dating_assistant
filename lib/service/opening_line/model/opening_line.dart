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
  const OpeningLine({required this.id, required this.text, this.match});

  factory OpeningLine.fromJson(Map<String, dynamic> json) {
    final match = json['match'] as Map<String, dynamic>?;
    return OpeningLine(
      id: json['id'] as String,
      text: json['line'] as String,
      match: match == null ? null : MatchDetails.fromJson(match),
    );
  }

  final String id;

  final String text;

  /// Что сервер прочитал в анкете со скриншота: следующие фразы просим по нему, скриншот второй раз не шлём.
  final MatchDetails? match;
}

/// Фразы для одного мэтча — одна запись в истории, сколько ни нажимай «Another one».
/// Сервер ничего не помнит: уже предложенные фразы ему шлём мы.
class OpeningLineSession {
  const OpeningLineSession({required this.id, required this.updatedAt, required this.lines, this.match});

  /// Сессия с первой фразой.
  factory OpeningLineSession.start(OpeningLine line, {MatchDetails? match, DateTime? at}) {
    final now = at ?? DateTime.now();
    return OpeningLineSession(
      id: 'opening-lines-${now.microsecondsSinceEpoch}',
      updatedAt: now,
      lines: [line.text],
      match: match ?? line.match,
    );
  }

  factory OpeningLineSession.fromJson(Map<String, dynamic> json) {
    final match = json['match'] as Map<String, dynamic>?;
    return OpeningLineSession(
      id: json['id'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lines: (json['lines'] as List<dynamic>).cast<String>(),
      match: match == null ? null : MatchDetails.fromJson(match),
    );
  }

  final String id;

  final DateTime updatedAt;

  /// Все фразы по порядку, последняя — на экране.
  final List<String> lines;

  /// Что известно о мэтче: введено или прочитано в анкете.
  final MatchDetails? match;

  /// Последняя фраза — с ней сессия открывается из истории.
  OpeningLine get latest => OpeningLine(id: '$id-${lines.length}', text: lines.last, match: match);

  /// Сессия со следующей фразой.
  OpeningLineSession adding(OpeningLine line, {required DateTime at}) => OpeningLineSession(
    id: id,
    updatedAt: at,
    lines: [...lines, line.text],
    match: match ?? line.match,
  );

  Map<String, dynamic> toJson() {
    final match = this.match;
    return {
      'id': id,
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'lines': lines,
      if (match != null && !match.isEmpty) 'match': match.toJson(),
    };
  }
}
