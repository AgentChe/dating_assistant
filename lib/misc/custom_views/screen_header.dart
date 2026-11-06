import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/glass_button.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// Шапка экрана из Figma: «назад», заголовок и, если нужно, кнопка справа.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, required this.onBack, this.trailing});

  /// 20/25 ExtraBold — заголовки экранов в шапке.
  static final titleStyle = Fonts.title.copyWith(fontSize: 20, height: 25.2 / 20);

  final String title;

  final VoidCallback onBack;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          GlassButton(icon: AppIcons.chevronLeft, onPressed: onBack, semanticLabel: 'Back'),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (trailing != null) ...[const SizedBox(width: 16), trailing],
        ],
      ),
    );
  }
}
