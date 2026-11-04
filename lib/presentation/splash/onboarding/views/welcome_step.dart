import 'dart:ui';

import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/bottom_buttons.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_view_model.dart';
import 'package:flutter/widgets.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key, required this.viewModel});

  final OnboardingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(child: _Hero()),
        const SizedBox(height: 31),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Never wonder what to text again', style: Fonts.display),
              SizedBox(height: 12),
              Text(
                'Cue reads your chats, shows where things stand and writes the next message — in your voice.',
                style: Fonts.subtitle,
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [_Tag('🙋 About you'), _Tag('🗣️ Your voice'), _Tag('💬 Try it on a chat')],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        BottomButtons(
          buttons: [PrimaryButton(title: 'Get started', onPressed: viewModel.next)],
        ),
      ],
    );
  }
}

/// Композиция 3D-иконок со свечением, 428×440 как в Figma; на маленьких экранах уменьшается целиком.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: 428,
        height: 440,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -6,
              top: 0,
              width: 440,
              height: 440,
              child: Opacity(opacity: 0.2, child: Image.asset(AppImages.glow)),
            ),
            const _Icon3d(AppImages.quotes3d, left: 24, top: 36, size: 123),
            const _Icon3d(AppImages.sparkle3d, left: 328, top: 76, size: 64),
            const _Icon3d(AppImages.gallery3d, left: 42, top: 286, size: 95, opacity: 0.8),
            const _Icon3d(AppImages.question3d, left: 269, top: 272, size: 130),
            const _Icon3d(AppImages.chat3d, left: 116, top: 122, size: 196, isInFocus: true),
          ],
        ),
      ),
    );
  }
}

class _Icon3d extends StatelessWidget {
  const _Icon3d(
    this.asset, {
    required this.left,
    required this.top,
    required this.size,
    this.opacity = 1,
    this.isInFocus = false,
  });

  final String asset;

  final double left;

  final double top;

  final double size;

  final double opacity;

  /// Иконки вокруг размыты, как будто не в фокусе (layer blur 4 в Figma).
  final bool isInFocus;

  @override
  Widget build(BuildContext context) {
    final image = Opacity(
      opacity: opacity,
      child: Image.asset(asset, width: size, height: size),
    );
    return Positioned(
      left: left,
      top: top,
      child: isInFocus ? image : ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2), child: image),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Appearance.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Appearance.hairline),
      ),
      child: Text(
        label,
        style: Fonts.label.copyWith(height: 20 / 14, color: const Color(0xB3FFFFFF)),
      ),
    );
  }
}
