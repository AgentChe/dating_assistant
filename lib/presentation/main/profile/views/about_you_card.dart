import 'package:dating_assistant/misc/extensions/profile_titles.dart';
import 'package:dating_assistant/presentation/main/profile/views/profile_row.dart';
import 'package:dating_assistant/presentation/main/profile/views/profile_section.dart';
import 'package:dating_assistant/service/profile/model/profile.dart';
import 'package:flutter/widgets.dart';

/// Карточка «About you»: пол, возраст и цель; любая строка открывает шторку с выбором.
class AboutYouCard extends StatelessWidget {
  const AboutYouCard({super.key, required this.profile, required this.onTap});

  final Profile profile;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            ProfileRow(emoji: '🙋', title: 'Gender', value: profile.gender.title, hasDivider: true, onTap: onTap),
            ProfileRow(emoji: '🎂', title: 'Age', value: profile.ageRange.title, hasDivider: true, onTap: onTap),
            ProfileRow(
              emoji: '💞',
              title: 'Looking for',
              value: profile.goal.shortTitle,
              hasDivider: false,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}
