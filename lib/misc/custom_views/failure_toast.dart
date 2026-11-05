import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/pressable.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// Плашка об ошибке: красный крестик и текст; по нажатию скрывается.
class FailureToast extends StatelessWidget {
  const FailureToast({super.key, required this.message, required this.onTap});

  final String message;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(1),
        decoration: const ShapeDecoration(
          shape: StadiumBorder(),
          // Тот же «стеклянный» ободок, что у круглых кнопок.
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x40FFFFFF), Color(0x0AFFFFFF), Color(0x26FFFFFF)],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(9, 9, 17, 9),
          decoration: const ShapeDecoration(shape: StadiumBorder(), color: Color(0xFF161616)),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF5757)),
                child: const SvgIcon(AppIcons.close, size: 16, color: Appearance.white),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message, style: Fonts.label)),
            ],
          ),
        ),
      ),
    );
  }
}
