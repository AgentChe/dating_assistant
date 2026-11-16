import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// Блок профиля: заголовок, подсказка справа, если есть, и карточка под ним.
class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key, required this.title, this.hint, required this.child});

  /// 16/20 SemiBold — заголовки блоков и групп в шторках.
  static final titleStyle = Fonts.headline.copyWith(height: 20 / 16);

  final String title;

  final String? hint;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: titleStyle)),
            if (hint case final hint?) Text(hint, style: Fonts.eyebrow.copyWith(fontWeight: FontWeight.w400)),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// Тёмная карточка профиля.
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, this.padding = EdgeInsets.zero, required this.child});

  final EdgeInsets padding;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: Appearance.surface, borderRadius: BorderRadius.circular(20)),
      child: child,
    );
  }
}
