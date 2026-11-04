import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// «What you get»: что даёт Free и что даёт Plus.
class PlanComparison extends StatelessWidget {
  const PlanComparison({super.key});

  static const _columnWidth = 84.0;

  /// Строки таблицы: null в колонке — галочка.
  static const _rows = [
    ('Screenshot breakdowns', null, null),
    ('Coach messages', '3 a week', 'Unlimited'),
    ('Opening lines', '3 a week', 'Unlimited'),
    ('Whole-chat import', '—', null),
    ('Voice learning', 'From setup', 'Every chat'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      decoration: BoxDecoration(color: Appearance.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text('What you get', style: Fonts.headline.copyWith(height: 20 / 16)),
              ),
              const SizedBox(
                width: _columnWidth,
                child: Center(child: Text('Free', style: Fonts.eyebrow)),
              ),
              const SizedBox(
                width: _columnWidth,
                child: Center(child: _PlusBadge()),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final (label, free, plus) in _rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0x14FFFFFF))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(label, style: Fonts.caption.copyWith(color: Appearance.white)),
                  ),
                  SizedBox(
                    width: _columnWidth,
                    child: Center(child: _Cell(text: free, isPlus: false)),
                  ),
                  SizedBox(
                    width: _columnWidth,
                    child: Center(child: _Cell(text: plus, isPlus: true)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.text, required this.isPlus});

  final String? text;

  final bool isPlus;

  @override
  Widget build(BuildContext context) {
    final text = this.text;
    if (text == null) return SvgIcon(AppIcons.check, size: 16, color: isPlus ? Appearance.white : Appearance.grey);

    return Text(
      text,
      style: isPlus ? Fonts.caption.copyWith(fontWeight: FontWeight.w600, color: Appearance.white) : Fonts.caption,
    );
  }
}

class _PlusBadge extends StatelessWidget {
  const _PlusBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: Appearance.pastelGradient, borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          'Plus',
          style: Fonts.eyebrow.copyWith(fontWeight: FontWeight.w600, color: Appearance.black),
        ),
      ),
    );
  }
}
