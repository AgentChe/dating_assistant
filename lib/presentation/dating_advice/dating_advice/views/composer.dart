import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/glass_panel.dart';
import 'package:dating_assistant/misc/custom_views/pressable.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:dating_assistant/misc/extensions/coach_titles.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/service/coach/model/coach_tone.dart';
import 'package:flutter/material.dart';

/// Поле ввода коуча (composer из Figma): текст, «+» для скриншота переписки, тон и отправка.
/// Стеклянная панель над затемнением, снизу — отступ над home indicator или клавиатурой.
class Composer extends StatelessWidget {
  const Composer({
    super.key,
    required this.controller,
    required this.tone,
    required this.isEnabled,
    required this.canSend,
    required this.onChanged,
    required this.onSend,
    required this.onAttach,
    required this.onTone,
    required this.onDisabledTap,
  });

  /// Текст — #BFBFBF в режиме Linear Dodge поверх стекла.
  static const _textColor = Color(0xFFCECECE);

  /// Подсказка — белый 40% в режиме Linear Dodge поверх стекла.
  static const _hintColor = Color(0xFF757575);

  final TextEditingController controller;

  final CoachTone tone;

  /// false — состояние Disabled: бесплатные генерации кончились, нажатие на панель открывает Cue Plus.
  final bool isEnabled;

  /// Отправка коралловая, когда есть текст и коуч не печатает.
  final bool canSend;

  final ValueChanged<String> onChanged;

  final VoidCallback onSend;

  final VoidCallback onAttach;

  final VoidCallback onTone;

  final VoidCallback onDisabledTap;

  @override
  Widget build(BuildContext context) {
    // Без межбуквенного 0.5 из стиля bodyLarge, который TextField берёт из темы.
    final style = Fonts.body.copyWith(height: 20.16 / 16, letterSpacing: 0, color: _textColor);
    return Stack(
      children: [
        const Positioned.fill(child: _Backdrop()),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, math.max(MediaQuery.paddingOf(context).bottom + 2, 12)),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isEnabled ? null : onDisabledTap,
            child: GlassPanel(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: controller,
                    enabled: isEnabled,
                    onChanged: onChanged,
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardAppearance: Brightness.dark,
                    style: style,
                    cursorColor: Appearance.accent,
                    cursorWidth: 2,
                    cursorHeight: 20,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Describe your situation',
                      hintStyle: style.copyWith(color: _hintColor),
                      contentPadding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: Row(
                      children: [
                        _AttachButton(onTap: isEnabled ? onAttach : null),
                        const SizedBox(width: 12),
                        _ToneChip(tone: tone, onTap: isEnabled ? onTone : null),
                        const Spacer(),
                        _SendButton(onTap: canSend ? onSend : null),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Затемнение под панелью: снизу 90%, к верху сходит на нет; под ним размытие, как у шапки.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  static final _blur = ImageFilter.blur(sigmaX: 8, sigmaY: 8);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Размытие начинается ниже верхних 12, где затемнение уже заметно, — иначе виден его край.
        Positioned(
          left: 0,
          right: 0,
          top: 12,
          bottom: 0,
          child: ClipRect(
            child: BackdropFilter(filter: _blur, child: const SizedBox.expand()),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xE6000000), Color(0xB8000000), Color(0x00000000)],
                stops: [0, 0.7, 1],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// «+» — приложить скриншот переписки.
class _AttachButton extends StatelessWidget {
  const _AttachButton({required this.onTap});

  /// null — панель недоступна, «+» приглушён (белый 28% поверх кнопки).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Attach a screenshot',
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x14FFFFFF)),
        child: SvgIcon(
          AppIcons.plus,
          size: 21,
          color: onTap == null ? const Color(0xFF696969) : const Color(0xFFE1E1E1),
        ),
      ),
    );
  }
}

/// Тон ответов: «✦ Auto» на пастельной пилюле.
class _ToneChip extends StatelessWidget {
  const _ToneChip({required this.tone, required this.onTap});

  final CoachTone tone;

  /// null — панель недоступна: пилюля белая 14%, текст белый 28%.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Tone',
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          gradient: isEnabled ? Appearance.pastelGradient : null,
          color: isEnabled ? null : const Color(0x24FFFFFF),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            '${tone.emoji} ${tone.title}',
            style: Fonts.body.copyWith(
              height: 20.16 / 16,
              color: isEnabled ? Appearance.black : const Color(0x47FFFFFF),
            ),
          ),
        ),
      ),
    );
  }
}

/// Отправка: серая, пока отправлять нечего, коралловая — когда можно.
class _SendButton extends StatelessWidget {
  const _SendButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Send',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isEnabled ? Appearance.accent : Appearance.surfaceRaised,
        ),
        child: SvgIcon(AppIcons.send, color: isEnabled ? Appearance.black : Appearance.grey),
      ),
    );
  }
}
