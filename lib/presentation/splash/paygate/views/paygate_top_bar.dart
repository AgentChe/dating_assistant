import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/glass_button.dart';
import 'package:dating_assistant/misc/custom_views/pressable.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// Закрепленная шапка: закрыть и «Restore». Когда контент уехал под неё, появляется затемнение.
class PaygateTopBar extends StatelessWidget {
  const PaygateTopBar({
    super.key,
    required this.isScrolled,
    required this.isEnabled,
    required this.onClose,
    required this.onRestore,
  });

  final bool isScrolled;

  /// Во время покупки закрыть пейгейт и восстановить покупки нельзя.
  final bool isEnabled;

  final VoidCallback onClose;

  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: isScrolled ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Appearance.black, Color(0xE6000000), Color(0x00000000)],
                    stops: [0, 0.6, 1],
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                AnimatedOpacity(
                  opacity: isEnabled ? 1 : 0.4,
                  duration: const Duration(milliseconds: 200),
                  child: GlassButton(
                    icon: AppIcons.close,
                    onPressed: isEnabled ? onClose : null,
                    semanticLabel: 'Close',
                  ),
                ),
                const Spacer(),
                Pressable(
                  onTap: isEnabled ? onRestore : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'Restore',
                      style: Fonts.button.copyWith(color: isEnabled ? Appearance.grey : const Color(0x47FFFFFF)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
