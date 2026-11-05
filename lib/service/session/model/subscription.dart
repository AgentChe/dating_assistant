/// Действующая подписка Cue Plus — для карточки плана в профиле.
class Subscription {
  const Subscription({
    required this.productId,
    required this.expiresAt,
    required this.isTrial,
    required this.willRenew,
  });

  final String productId;

  /// Конец текущего периода; null — SDK не прислал дату.
  final DateTime? expiresAt;

  /// Идёт бесплатный пробный период.
  final bool isTrial;

  /// Продлится автоматически: пользователь не отменил подписку.
  final bool willRenew;
}
