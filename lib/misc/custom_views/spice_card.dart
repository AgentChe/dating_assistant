import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/extensions/profile_titles.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Карточка остроты: ползунок от Soft до Spicy и подпись выбранной ступени — в профиле и у первой фразы.
class SpiceCard extends StatelessWidget {
  const SpiceCard({super.key, required this.spice, required this.onChanged});

  final SpiceLevel spice;

  final ValueChanged<SpiceLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    final endStyle = Fonts.button.copyWith(height: 20 / 16);
    return Container(
      // Сверху 8, а не 20 из Figma: ряд с ползунком выше на 24 ради удобного касания, отступы те же.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: BoxDecoration(color: Appearance.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            children: [
              Text('Soft', style: endStyle.copyWith(color: const Color(0xFFFFA48E))),
              const SizedBox(width: 16),
              Expanded(
                child: SpiceSlider(value: spice, onChanged: onChanged),
              ),
              const SizedBox(width: 16),
              Text('Spicy', style: endStyle.copyWith(color: const Color(0xFFFF5757))),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Text(
              spice.description,
              key: ValueKey(spice),
              textAlign: TextAlign.center,
              style: Fonts.caption.copyWith(fontWeight: FontWeight.w300, height: 17.6 / 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ползунок остроты: пять ступеней, над бегунком — название выбранной.
class SpiceSlider extends StatelessWidget {
  const SpiceSlider({super.key, required this.value, required this.onChanged});

  static const _height = 44.0;

  static const _thumb = 24.0;

  static const _duration = Duration(milliseconds: 150);

  final SpiceLevel value;

  final ValueChanged<SpiceLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    const levels = SpiceLevel.values;
    final index = value.index;
    final next = index < levels.length - 1 ? levels[index + 1] : null;
    final previous = index > 0 ? levels[index - 1] : null;

    return Semantics(
      slider: true,
      label: 'Default spice',
      value: value.title,
      increasedValue: next?.title,
      decreasedValue: previous?.title,
      onIncrease: next == null ? null : () => _select(next),
      onDecrease: previous == null ? null : () => _select(previous),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final step = (constraints.maxWidth - _thumb) / (levels.length - 1);
          final center = _thumb / 2 + index * step;
          SpiceLevel levelAt(Offset position) =>
              levels[((position.dx - _thumb / 2) / step).round().clamp(0, levels.length - 1)];

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => _select(levelAt(details.localPosition)),
            onHorizontalDragStart: (details) => _select(levelAt(details.localPosition)),
            onHorizontalDragUpdate: (details) => _select(levelAt(details.localPosition)),
            child: SizedBox(
              height: _height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: _height / 2 - 2,
                    height: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFFAE96), Color(0xFFFF5656)]),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: _duration,
                    curve: Curves.easeOut,
                    left: center - _thumb / 2,
                    top: (_height - _thumb) / 2,
                    width: _thumb,
                    height: _thumb,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: Appearance.accentGradient,
                        border: Border.fromBorderSide(BorderSide(color: Color(0x59FFFFFF), width: 0.5)),
                      ),
                    ),
                  ),
                  // Название ступени над бегунком, в 8 от него.
                  AnimatedPositioned(
                    duration: _duration,
                    curve: Curves.easeOut,
                    left: center - 50,
                    width: 100,
                    bottom: _height - (_height - _thumb) / 2 + 8,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: const ShapeDecoration(shape: StadiumBorder(), color: Appearance.white),
                        child: Text(value.title, style: Fonts.eyebrow.copyWith(color: Appearance.black)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _select(SpiceLevel level) {
    if (level == value) return;
    HapticFeedback.selectionClick();
    onChanged(level);
  }
}
