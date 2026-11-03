import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/pastel_card.dart';
import 'package:dating_assistant/misc/custom_views/pressable.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_content.dart';
import 'package:flutter/widgets.dart';

/// Колода карточек «Would you send this?»: свайп вправо — «That’s me», влево — «Not me».
/// Кнопки под колодой делают то же самое.
class VoiceDeck extends StatefulWidget {
  const VoiceDeck({super.key, required this.index, required this.onAnswer});

  /// Текущая карточка из OnboardingContent.voiceSamples; следующие лежат стопкой сзади.
  final int index;

  final void Function({required bool isMe}) onAnswer;

  @override
  State<VoiceDeck> createState() => _VoiceDeckState();
}

class _VoiceDeckState extends State<VoiceDeck> with SingleTickerProviderStateMixin {
  static const _cardHeight = 380.0;

  /// Сдвиг, после которого отпущенная карточка улетает.
  static const _threshold = 100.0;

  late final _controller = AnimationController(vsync: this)..addListener(_onTick);

  Animation<double>? _flight;

  var _dx = 0.0;

  var _isLeaving = false;

  @override
  void didUpdateWidget(VoiceDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controller.stop();
      _flight = null;
      _dx = 0;
      _isLeaving = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const samples = OnboardingContent.voiceSamples;
    final index = widget.index.clamp(0, samples.length - 1);
    final cardsBehind = samples.length - index - 1;
    final drag = (_dx / _threshold).clamp(-1.0, 1.0);

    return Column(
      children: [
        SizedBox(
          height: _cardHeight + 28,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (cardsBehind > 1)
                const Positioned(
                  top: 28,
                  left: 32,
                  right: 32,
                  height: _cardHeight,
                  child: _BackCard(color: Appearance.surfaceRaised),
                ),
              if (cardsBehind > 0)
                const Positioned(
                  top: 14,
                  left: 16,
                  right: 16,
                  height: _cardHeight,
                  child: _BackCard(color: Appearance.surfaceHigh),
                ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _cardHeight,
                child: GestureDetector(
                  onHorizontalDragUpdate: _isLeaving ? null : (details) => setState(() => _dx += details.delta.dx),
                  onHorizontalDragEnd: _isLeaving ? null : _onDragEnd,
                  child: Transform.translate(
                    offset: Offset(_dx, 0),
                    child: Transform.rotate(
                      angle: _dx / MediaQuery.sizeOf(context).width * 0.25,
                      child: _AppearingCard(
                        key: ValueKey(index),
                        child: _SampleCard(sample: samples[index], drag: drag),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AnswerButton(isMe: false, isHighlighted: drag <= -0.5, onTap: () => _leave(isMe: false)),
            const SizedBox(width: 56),
            _AnswerButton(isMe: true, isHighlighted: drag >= 0.5, onTap: () => _leave(isMe: true)),
          ],
        ),
      ],
    );
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() >= 800) {
      _leave(isMe: velocity > 0);
    } else if (_dx.abs() >= _threshold) {
      _leave(isMe: _dx > 0);
    } else {
      _animateTo(0, const Duration(milliseconds: 250));
    }
  }

  Future<void> _leave({required bool isMe}) async {
    if (_isLeaving) return;

    _isLeaving = true;
    final width = MediaQuery.sizeOf(context).width;
    await _animateTo(isMe ? width * 1.4 : -width * 1.4, const Duration(milliseconds: 280));
    if (mounted) widget.onAnswer(isMe: isMe);
  }

  Future<void> _animateTo(double target, Duration duration) {
    _flight = Tween(begin: _dx, end: target).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.duration = duration;
    return _controller.forward(from: 0);
  }

  void _onTick() {
    final flight = _flight;
    if (flight != null) setState(() => _dx = flight.value);
  }
}

/// Новая верхняя карточка выезжает из стопки.
class _AppearingCard extends StatelessWidget {
  const _AppearingCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 14 * (1 - value)),
        child: Transform.scale(scale: 0.92 + 0.08 * value, child: child),
      ),
      child: child,
    );
  }
}

class _SampleCard extends StatelessWidget {
  const _SampleCard({required this.sample, required this.drag});

  static const _faded = Color(0x99000000);

  final VoiceSample sample;

  /// От −1 до 1: насколько карточку утащили влево или вправо.
  final double drag;

  @override
  Widget build(BuildContext context) {
    return PastelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sample.emoji, style: const TextStyle(fontSize: 32, height: 1.25)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'They wrote',
                      style: Fonts.eyebrow.copyWith(height: 16 / 12, color: _faded),
                    ),
                    const SizedBox(height: 2),
                    Text(sample.theyWrote, style: Fonts.body.copyWith(color: _faded)),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: Opacity(
                opacity: drag.abs(),
                child: _Stamp(isMe: drag >= 0),
              ),
            ),
          ),
          Text(sample.reply, style: Fonts.phrase),
        ],
      ),
    );
  }
}

/// Плашка «Not me» / «That’s me», которая проявляется при свайпе.
class _Stamp extends StatelessWidget {
  const _Stamp({required this.isMe});

  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final foreground = isMe ? Appearance.black : Appearance.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: ShapeDecoration(shape: const StadiumBorder(), color: isMe ? Appearance.accent : Appearance.black),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgIcon(isMe ? AppIcons.check : AppIcons.close, size: 26, color: foreground),
          const SizedBox(width: 8),
          Text(
            isMe ? 'That’s me' : 'Not me',
            style: Fonts.title.copyWith(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w700, color: foreground),
          ),
        ],
      ),
    );
  }
}

class _BackCard extends StatelessWidget {
  const _BackCard({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Appearance.hairline),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({required this.isMe, required this.isHighlighted, required this.onTap});

  final bool isMe;

  /// Карточку тянут в сторону этой кнопки.
  final bool isHighlighted;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMe
                  ? Appearance.accent
                  : isHighlighted
                  ? Appearance.surfaceHigh
                  : Appearance.surfaceRaised,
              border: isMe
                  ? null
                  : Border.all(color: isHighlighted ? const Color(0x3DFFFFFF) : const Color(0x24FFFFFF)),
            ),
            child: Center(
              child: SvgIcon(
                isMe ? AppIcons.check : AppIcons.close,
                size: 28,
                color: isMe ? Appearance.black : Appearance.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: Fonts.label.copyWith(height: 20 / 14, color: isHighlighted ? Appearance.white : Appearance.grey),
            child: Text(isMe ? 'That’s me' : 'Not me'),
          ),
        ],
      ),
    );
  }
}
