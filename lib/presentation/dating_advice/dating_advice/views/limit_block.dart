import 'package:dating_assistant/misc/custom_views/inline_banner.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:flutter/widgets.dart';

/// Вместо поля ввода, когда бесплатные сообщения кончились (dating advice — limit из Figma):
/// баннер «You’ve used your 3 free messages», «Go unlimited» и «Not now».
class LimitBlock extends StatelessWidget {
  const LimitBlock({super.key, required this.freeLimit, required this.onGoUnlimited, required this.onNotNow});

  /// Бесплатных сообщений в неделю.
  final int freeLimit;

  final VoidCallback onGoUnlimited;

  /// Свернуть блок в неактивное поле ввода.
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Как в макете: над home indicator ещё 43 — блок стоит выше кнопок внизу других экранов.
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.paddingOf(context).bottom + 43),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InlineBanner(
            tone: BannerTone.accent,
            title: 'You’ve used your $freeLimit free messages',
            message: 'Go unlimited to keep the conversation going.',
          ),
          const SizedBox(height: 34),
          PrimaryButton(title: 'Go unlimited', onPressed: onGoUnlimited),
          const SizedBox(height: 4),
          PrimaryButton.plain(title: 'Not now', onPressed: onNotNow),
        ],
      ),
    );
  }
}
