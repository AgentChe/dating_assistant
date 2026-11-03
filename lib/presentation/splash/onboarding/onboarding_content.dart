import 'package:dating_assistant/service/profile/model/hardest_part.dart';
import 'package:dating_assistant/service/profile/model/voice.dart';

/// Карточка «Would you send this?»: чужое сообщение и ответ в определённом стиле.
class VoiceSample {
  const VoiceSample({required this.emoji, required this.theyWrote, required this.reply, required this.trait});

  final String emoji;

  final String theyWrote;

  final String reply;

  /// Какую черту голоса проверяет карточка: «That’s me» — черта есть.
  final VoiceTrait trait;
}

/// Фраза, которую Cue пишет голосом пользователя.
class VoicePhrase {
  const VoicePhrase({required this.direct, this.relaxed, required this.emoji});

  /// Для тех, кто говорит прямо.
  final String direct;

  /// Для тех, кто заходит издалека; null — как [direct].
  final String? relaxed;

  final String emoji;

  String styled(Voice voice) {
    var text = voice.has(VoiceTrait.direct) ? direct : relaxed ?? direct;
    if (voice.has(VoiceTrait.emoji)) text = '$text $emoji';
    if (voice.has(VoiceTrait.lowercase)) return text;
    return text.replaceAllMapped(
      RegExp(r'(^|[.?!]\s+)([a-z])'),
      (match) => '${match[1]}${match[2]!.toUpperCase()}',
    );
  }
}

/// Ответ на сообщение из примера переписки.
class TryItAnswer {
  const TryItAnswer({required this.emoji, required this.text, required this.feedback});

  final String emoji;

  final String text;

  /// Чем ответ Cue лучше этого.
  final String feedback;
}

/// С чего начать после онбординга.
enum StartingPoint { analyzeChat, openingLine, datingAdvice }

/// Тексты онбординга, которых нет в модели профиля: примеры, пояснения, рекомендации.
abstract final class OnboardingContent {
  /// Каждая карточка проверяет одну черту голоса.
  static const voiceSamples = [
    VoiceSample(
      emoji: '🌊',
      theyWrote: 'just got back from the coast. the view was unreal',
      reply: 'haha wait where was this',
      trait: VoiceTrait.lowercase,
    ),
    VoiceSample(
      emoji: '🍝',
      theyWrote: 'i finally made pasta from scratch. it took four hours',
      reply: 'okay that’s actually impressive 😭🔥',
      trait: VoiceTrait.emoji,
    ),
    VoiceSample(
      emoji: '🍸',
      theyWrote: 'found the best tiny bar near my place',
      reply: 'so when are you taking me',
      trait: VoiceTrait.direct,
    ),
  ];

  /// Пример на экране «That’s your voice».
  static const voicePreview = VoicePhrase(
    direct: 'okay that tent story is iconic. when’s the next trip',
    relaxed: 'okay that tent story is iconic. tell me everything sometime',
    emoji: '😂',
  );

  /// Сколько голоса Cue знает после трёх карточек.
  static const voiceLearned = 0.3;

  static const sampleContact = 'Nika, 28';

  static const sampleMessage = 'ran off to the mountains for the weekend and honestly do not want to come back 🙃';

  static const tryItAnswers = [
    TryItAnswer(
      emoji: '😐',
      text: 'haha nice, enjoy',
      feedback: '“Enjoy” closes the chat. Cue asks something, so Nika has a reason to reply.',
    ),
    TryItAnswer(
      emoji: '🙂',
      text: 'lucky! where did you go?',
      feedback: 'You asked where — Nika already said. Cue asks why, so the chat keeps going.',
    ),
    TryItAnswer(
      emoji: '😩',
      text: 'omg so jealous',
      feedback: '“Jealous” makes it about you. Cue stays curious about Nika, so the chat keeps going.',
    ),
    TryItAnswer(
      emoji: '🤷',
      text: 'no idea — show me',
      feedback: 'Pick up what Nika shared and hand a question back — that’s how a chat keeps going.',
    ),
  ];

  /// Ответ Cue на сообщение из примера.
  static const cueReply = VoicePhrase(
    direct: 'sounds like the right call. what’s up there worth staying for?',
    emoji: '🏔️',
  );

  /// Заголовки на экране «Made for you» — от второго лица, в отличие от вариантов ответа.
  static String insightTitle(HardestPart part) => switch (part) {
    HardestPart.startingConversation => 'Starting the conversation',
    HardestPart.keepingItGoing => 'Keeping it going',
    HardestPart.knowingIfInterested => 'Knowing if they’re into you',
    HardestPart.whenTheyGoQuiet => 'When they go quiet',
    HardestPart.askingThemOut => 'Asking them out',
  };

  static String insightText(HardestPart part) => switch (part) {
    HardestPart.startingConversation => 'Cue writes an opening line from their profile — no more “hey”.',
    HardestPart.keepingItGoing => 'Your coach hands you the next message, word for word.',
    HardestPart.knowingIfInterested => 'Cue reads interest from the chat itself — who asks, who carries it.',
    HardestPart.whenTheyGoQuiet => 'Cue tells you if a follow-up is worth it and writes one that doesn’t beg.',
    HardestPart.askingThemOut => 'Cue spots when it’s time and words the invite so it’s easy to say yes.',
  };

  /// Порядок, в котором трудности определяют, с чего начать: важнее — раньше.
  static const hardestPartPriority = [
    HardestPart.knowingIfInterested,
    HardestPart.keepingItGoing,
    HardestPart.startingConversation,
    HardestPart.whenTheyGoQuiet,
    HardestPart.askingThemOut,
  ];

  static StartingPoint startingPoint(HardestPart part) => switch (part) {
    HardestPart.knowingIfInterested || HardestPart.keepingItGoing => StartingPoint.analyzeChat,
    HardestPart.startingConversation => StartingPoint.openingLine,
    HardestPart.whenTheyGoQuiet || HardestPart.askingThemOut => StartingPoint.datingAdvice,
  };

  /// Почему предлагаем начать именно так — подсказка на экране плана.
  static String startingTip(HardestPart part) => switch (part) {
    HardestPart.knowingIfInterested =>
      'You said knowing if they’re into you is the hardest part. A breakdown answers exactly that.',
    HardestPart.keepingItGoing =>
      'You said keeping it going is the hardest part. A breakdown ends with your next message.',
    HardestPart.startingConversation =>
      'You said starting the conversation is the hardest part. An opening line from their profile fixes that.',
    HardestPart.whenTheyGoQuiet => 'You said it’s hardest when they go quiet. Your coach knows what to send next.',
    HardestPart.askingThemOut =>
      'You said asking them out is the hardest part. Your coach will tell you when — and how.',
  };

  static String startingTitle(StartingPoint point) => switch (point) {
    StartingPoint.analyzeChat => 'Analyze a chat',
    StartingPoint.openingLine => 'Get an opening line',
    StartingPoint.datingAdvice => 'Ask your coach',
  };

  static String startingAction(StartingPoint point) => switch (point) {
    StartingPoint.analyzeChat => 'Analyze my first chat',
    StartingPoint.openingLine => 'Get my first opening line',
    StartingPoint.datingAdvice => 'Ask my coach',
  };
}
