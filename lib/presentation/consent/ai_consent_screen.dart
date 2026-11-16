import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/misc/global_definitions.dart';
import 'package:dating_assistant/presentation/consent/views/privacy_facts.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Согласие на передачу переписок ИИ (Figma «AI consent», 480:3341) — правило App Review 5.1.2(i).
/// Открывается поверх всего перед первым запросом к ИИ: true — «Allow and continue», false — «Not now».
class AiConsentScreen extends StatelessWidget {
  const AiConsentScreen({super.key});

  static Route<bool> route() =>
      MaterialPageRoute<bool>(fullscreenDialog: true, builder: (_) => const AiConsentScreen());

  /// Закрыли жестом — то же, что «Not now»: ничего не отправляем.
  static Future<bool> present(BuildContext context) async =>
      await Navigator.of(context, rootNavigator: true).push(route()) ?? false;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final insets = EdgeInsets.fromLTRB(16, padding.top, 16, padding.bottom + 3);
    return Scaffold(
      backgroundColor: Appearance.black,
      body: Stack(
        children: [
          // Свечение с точечной текстурой за героем, как на пейгейте.
          Positioned(
            top: -74,
            left: -6,
            width: 440,
            height: 440,
            child: IgnorePointer(child: Opacity(opacity: 0.2, child: Image.asset(AppImages.glow))),
          ),
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: insets,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - insets.vertical),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Края картинки прозрачные: на узком экране их можно срезать, пузырь остаётся по центру.
                      SizedBox(
                        height: 168,
                        child: OverflowBox(
                          maxWidth: 396,
                          child: ExcludeSemantics(
                            child: Image.asset(AppImages.consentHero, width: 396, height: 168),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Privacy', style: Fonts.eyebrow),
                      const SizedBox(height: 12),
                      Semantics(
                        header: true,
                        child: Text('Allow Cue to share your chats with AI?', style: Fonts.title),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'It’s how Cue reads them and writes your lines. Nothing is sent until you allow it.',
                        style: Fonts.subtitle,
                      ),
                      const SizedBox(height: 24),
                      const PrivacyFacts(),
                      const Spacer(),
                      const SizedBox(height: 28),
                      const _Note(),
                      const SizedBox(height: 16),
                      PrimaryButton(title: 'Allow and continue', onPressed: () => Navigator.of(context).pop(true)),
                      const SizedBox(height: 8),
                      PrimaryButton.plain(title: 'Not now', onPressed: () => Navigator.of(context).pop(false)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// «Change this anytime in Profile · Privacy Policy»: ссылка — белым.
class _Note extends StatelessWidget {
  const _Note();

  @override
  Widget build(BuildContext context) {
    final style = Fonts.eyebrow.copyWith(fontWeight: FontWeight.w400, height: 16 / 12);
    // Одной строкой, пока влезает; с крупным системным шрифтом ссылка переносится целиком.
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          const TextSpan(text: 'Change this anytime in Profile  ·  '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Semantics(
              link: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    launchUrl(Uri.parse(GlobalDefinitions.privacyPolicyUrl), mode: LaunchMode.inAppBrowserView),
                child: Text('Privacy Policy', style: style.copyWith(color: Appearance.white)),
              ),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
