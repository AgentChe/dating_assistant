import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/pressable.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// Карточка тарифа: название, цена за период, пояснение и плашка выгоды сверху.
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.title,
    required this.price,
    required this.period,
    required this.note,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  final String title;

  final String price;

  final String period;

  final String note;

  final bool isSelected;

  final VoidCallback onTap;

  /// «Save 85%» над правым краем карточки.
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final badge = this.badge;
    return Pressable(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              // У выбранной карточки обводка затухает книзу, как в Figma.
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isSelected
                    ? const [Appearance.white, Color(0x00FFFFFF)]
                    : const [Color(0x24FFFFFF), Color(0x24FFFFFF)],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
              decoration: BoxDecoration(color: Appearance.surface, borderRadius: BorderRadius.circular(15)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title, style: Fonts.label.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      _Radio(isSelected: isSelected),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(price, style: Fonts.title.copyWith(fontSize: 22, height: 28 / 22)),
                      ),
                      const SizedBox(width: 4),
                      Text(period, style: Fonts.caption.copyWith(height: 18 / 14)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(note, style: Fonts.eyebrow.copyWith(height: 16 / 12)),
                ],
              ),
            ),
          ),
          if (badge != null) Positioned(top: -11, right: 12, child: _SavingBadge(badge)),
        ],
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? Appearance.white : null,
        border: isSelected ? null : Border.all(color: const Color(0x3DFFFFFF), width: 1.5),
      ),
      child: isSelected ? const Center(child: SvgIcon(AppIcons.check, size: 14, color: Appearance.black)) : null,
    );
  }
}

class _SavingBadge extends StatelessWidget {
  const _SavingBadge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: Appearance.pastelGradient, borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Text(
          text,
          style: Fonts.eyebrow.copyWith(fontWeight: FontWeight.w600, color: Appearance.black),
        ),
      ),
    );
  }
}
