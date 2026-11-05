import 'package:dating_assistant/misc/custom_views/app_bottom_sheet.dart';
import 'package:dating_assistant/misc/custom_views/pill_chip.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:dating_assistant/misc/extensions/profile_titles.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/presentation/main/profile/profile_view_model.dart';
import 'package:dating_assistant/presentation/main/profile/views/profile_section.dart';
import 'package:dating_assistant/service/profile/model/age_range.dart';
import 'package:dating_assistant/service/profile/model/dating_goal.dart';
import 'package:dating_assistant/service/profile/model/gender.dart';
import 'package:flutter/widgets.dart';

/// Шторка «About you»: пол, возраст и цель. «Save changes» возвращает выбор, профиль сохраняет экран.
class AboutYouSheet extends StatefulWidget {
  const AboutYouSheet({super.key, required this.initial});

  final AboutYou initial;

  /// Завершается выбором пользователя или null, если шторку закрыли без сохранения.
  static Future<AboutYou?> show(BuildContext context, AboutYou initial) =>
      AppBottomSheet.show<AboutYou>(context, builder: (_) => AboutYouSheet(initial: initial));

  @override
  State<AboutYouSheet> createState() => _AboutYouSheetState();
}

class _AboutYouSheetState extends State<AboutYouSheet> {
  late var _gender = widget.initial.gender;

  late var _ageRange = widget.initial.ageRange;

  late var _goal = widget.initial.goal;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About you', style: Fonts.headline.copyWith(fontSize: 22, height: 27.7 / 22)),
            const SizedBox(height: 4),
            const Text('We use it to tune how your lines sound.', style: Fonts.caption),
          ],
        ),
        _ChipGroup(
          title: 'Gender',
          chips: [
            for (final gender in Gender.values)
              PillChip(
                label: gender.title,
                isSelected: gender == _gender,
                onTap: () => setState(() => _gender = gender),
              ),
          ],
        ),
        _ChipGroup(
          title: 'Age',
          chips: [
            for (final ageRange in AgeRange.values)
              PillChip(
                label: ageRange.title,
                isSelected: ageRange == _ageRange,
                onTap: () => setState(() => _ageRange = ageRange),
              ),
          ],
        ),
        _ChipGroup(
          title: 'Looking for',
          chips: [
            for (final goal in DatingGoal.values)
              PillChip(
                label: goal.shortTitle,
                isSelected: goal == _goal,
                onTap: () => setState(() => _goal = goal),
              ),
          ],
        ),
        PrimaryButton(
          title: 'Save changes',
          onPressed: () => Navigator.pop<AboutYou>(context, (gender: _gender, ageRange: _ageRange, goal: _goal)),
        ),
      ],
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({required this.title, required this.chips});

  final String title;

  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: ProfileSection.titleStyle),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );
  }
}
