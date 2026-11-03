/// Черта стиля переписки, которую Cue повторяет в сообщениях.
enum VoiceTrait {
  /// Пишет строчными, без заглавных.
  lowercase,

  /// Ставит эмодзи.
  emoji,

  /// Говорит прямо, без долгих заходов.
  direct,
}

/// Голос пользователя: какие черты стиля у него есть.
class Voice {
  const Voice(this.traits);

  factory Voice.fromJson(List<dynamic> json) => Voice({
    for (final name in json) VoiceTrait.values.byName(name as String),
  });

  final Set<VoiceTrait> traits;

  bool has(VoiceTrait trait) => traits.contains(trait);

  List<String> toJson() => [
    for (final trait in VoiceTrait.values)
      if (has(trait)) trait.name,
  ];
}
