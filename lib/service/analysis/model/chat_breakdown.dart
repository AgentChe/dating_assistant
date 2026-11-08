/// С кем переписка; возраст — если он виден на скриншоте.
typedef ChatPartner = ({String name, int? age});

/// Главный вывод: «😍 Nika is into this — and doing most of the work.».
typedef ChatRead = ({String emoji, String verdict, String detail});

/// Интерес по шкале от 1 до [ChatBreakdown.interestSteps]: «Warm», 4 из 5.
typedef InterestLevel = ({int level, String label});

/// Наблюдение с доказательством из переписки: «Asked about you» — «“is that tent real…”».
typedef ChatSignal = ({String title, String proof});

/// Тема для разговора: «🏔️ Mountains».
typedef ChatTopic = ({String emoji, String title});

/// Манера переписки: «😜 Playful».
typedef ChatVibe = ({String emoji, String label});

enum ChatTrend { up, flat, down }

/// Куда идёт переписка: «Warming up ↗».
typedef ChatHeading = ({String label, ChatTrend trend, String detail});

/// Разбор переписки по скриншоту (Figma «Chat breakdown»). «Them» — собеседник, «you» — пользователь.
class ChatBreakdown {
  const ChatBreakdown({
    required this.id,
    required this.partner,
    required this.read,
    required this.theirInterest,
    required this.yourInterest,
    required this.theirWordShare,
    required this.yourWordShare,
    required this.goingWell,
    required this.watchOut,
    required this.topics,
    required this.theirVibe,
    required this.yourVibe,
    required this.heading,
    required this.nextMove,
  });

  factory ChatBreakdown.fromJson(Map<String, dynamic> json) {
    final partner = json['partner'] as Map<String, dynamic>;
    final read = json['read'] as Map<String, dynamic>;
    final interest = json['interest'] as Map<String, dynamic>;
    final wordShare = json['word_share'] as Map<String, dynamic>;
    final vibe = json['vibe'] as Map<String, dynamic>;
    final heading = json['heading'] as Map<String, dynamic>;

    InterestLevel interestLevel(Object? json) {
      final level = json as Map<String, dynamic>;
      return (level: level['level'] as int, label: level['label'] as String);
    }

    List<ChatSignal> signals(Object? json) => [
      for (final signal in (json as List<dynamic>).cast<Map<String, dynamic>>())
        (title: signal['title'] as String, proof: signal['proof'] as String),
    ];

    ChatVibe chatVibe(Object? json) {
      final vibe = json as Map<String, dynamic>;
      return (emoji: vibe['emoji'] as String, label: vibe['label'] as String);
    }

    return ChatBreakdown(
      id: json['id'] as String,
      partner: (name: partner['name'] as String, age: partner['age'] as int?),
      read: (emoji: read['emoji'] as String, verdict: read['verdict'] as String, detail: read['detail'] as String),
      theirInterest: interestLevel(interest['them']),
      yourInterest: interestLevel(interest['you']),
      theirWordShare: wordShare['them'] as int,
      yourWordShare: wordShare['you'] as int,
      goingWell: signals(json['going_well']),
      watchOut: signals(json['watch_out']),
      topics: [
        for (final topic in (json['topics'] as List<dynamic>).cast<Map<String, dynamic>>())
          (emoji: topic['emoji'] as String, title: topic['title'] as String),
      ],
      theirVibe: chatVibe(vibe['them']),
      yourVibe: chatVibe(vibe['you']),
      heading: (
        label: heading['label'] as String,
        trend: ChatTrend.values.asNameMap()[heading['trend']] ?? ChatTrend.flat,
        detail: heading['detail'] as String,
      ),
      nextMove: json['next_move'] as String,
    );
  }

  /// Тот же JSON, что прислал сервер, — так разбор хранится в истории и уходит коучу.
  Map<String, dynamic> toJson() {
    Map<String, dynamic> interestLevel(InterestLevel level) => {'level': level.level, 'label': level.label};
    List<Map<String, dynamic>> signals(List<ChatSignal> signals) => [
      for (final signal in signals) {'title': signal.title, 'proof': signal.proof},
    ];
    Map<String, dynamic> chatVibe(ChatVibe vibe) => {'emoji': vibe.emoji, 'label': vibe.label};

    return {
      'id': id,
      'partner': {'name': partner.name, 'age': ?partner.age},
      'read': {'emoji': read.emoji, 'verdict': read.verdict, 'detail': read.detail},
      'interest': {'them': interestLevel(theirInterest), 'you': interestLevel(yourInterest)},
      'word_share': {'them': theirWordShare, 'you': yourWordShare},
      'going_well': signals(goingWell),
      'watch_out': signals(watchOut),
      'topics': [
        for (final topic in topics) {'emoji': topic.emoji, 'title': topic.title},
      ],
      'vibe': {'them': chatVibe(theirVibe), 'you': chatVibe(yourVibe)},
      'heading': {'label': heading.label, 'trend': heading.trend.name, 'detail': heading.detail},
      'next_move': nextMove,
    };
  }

  /// Делений на шкале интереса.
  static const interestSteps = 5;

  final String id;

  final ChatPartner partner;

  final ChatRead read;

  final InterestLevel theirInterest;

  final InterestLevel yourInterest;

  /// Доля слов в переписке, проценты.
  final int theirWordShare;

  final int yourWordShare;

  final List<ChatSignal> goingWell;

  final List<ChatSignal> watchOut;

  final List<ChatTopic> topics;

  final ChatVibe theirVibe;

  final ChatVibe yourVibe;

  final ChatHeading heading;

  /// Совет, что написать дальше.
  final String nextMove;
}
