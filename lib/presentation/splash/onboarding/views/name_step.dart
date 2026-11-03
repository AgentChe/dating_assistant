import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_view_model.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/onboarding_step_layout.dart';
import 'package:flutter/material.dart';

class NameStep extends StatefulWidget {
  const NameStep({super.key, required this.viewModel});

  final OnboardingViewModel viewModel;

  @override
  State<NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<NameStep> {
  late final _controller = TextEditingController(text: widget.viewModel.name);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return OnboardingStepLayout(
      content: [
        const OnboardingTitle(
          eyebrow: 'About you',
          title: 'First, what should we call you?',
          subtitle: 'A first name or a nickname — your coach will use it.',
        ),
        const SizedBox(height: 32),
        const Text('Your name', style: Fonts.label),
        const SizedBox(height: 10),
        TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          keyboardAppearance: Brightness.dark,
          style: Fonts.body,
          cursorColor: Appearance.accent,
          cursorWidth: 2,
          cursorHeight: 22,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Appearance.surfaceRaised,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Appearance.hairline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0x99FFFFFF), width: 1.5),
            ),
          ),
          onChanged: viewModel.changeName,
          onSubmitted: (_) => viewModel.next(),
        ),
      ],
      buttons: [PrimaryButton(title: 'Continue', onPressed: viewModel.canContinue ? viewModel.next : null)],
    );
  }
}
