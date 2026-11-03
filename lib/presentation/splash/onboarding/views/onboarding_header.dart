import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/glass_button.dart';
import 'package:dating_assistant/misc/custom_views/pressable.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// Шапка онбординга: «назад», прогресс по трём главам и «Skip» справа.
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({super.key, required this.progress, required this.onBack, this.onSkip});

  /// Высота вместе с отступом сверху — шаги отступают на неё, чтобы шапка не перекрывала содержимое.
  static const height = 59.0;

  /// Заполненность глав About you, Your voice, Try it: от 0 до 3.
  final double progress;

  final VoidCallback onBack;

  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final onSkip = this.onSkip;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 0),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            GlassButton(icon: AppIcons.chevronLeft, onPressed: onBack, semanticLabel: 'Back'),
            const SizedBox(width: 16),
            Expanded(child: _ChapterProgress(progress: progress)),
            const SizedBox(width: 16),
            SizedBox(
              width: 48,
              child: onSkip == null
                  ? null
                  : Pressable(
                      onTap: onSkip,
                      child: const SizedBox.expand(
                        child: Center(child: Text('Skip', style: Fonts.caption)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterProgress extends StatelessWidget {
  const _ChapterProgress({required this.progress});

  static const _chapters = 3;

  final double progress;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: progress),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, _) => Row(
        children: [
          for (var chapter = 0; chapter < _chapters; chapter++) ...[
            if (chapter > 0) const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 4,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(color: Appearance.surfaceRaised, borderRadius: BorderRadius.circular(2)),
                child: FractionallySizedBox(
                  widthFactor: (value - chapter).clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Appearance.white, borderRadius: BorderRadius.circular(2)),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
