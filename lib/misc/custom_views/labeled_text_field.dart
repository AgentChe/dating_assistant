import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Поле ввода из Figma (Input/text): подпись сверху и тёмное поле со скруглением 16.
class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.sentences,
    this.minLines = 1,
  });

  final String label;

  final String hint;

  final ValueChanged<String> onChanged;

  final TextInputType? keyboardType;

  final List<TextInputFormatter>? inputFormatters;

  final TextCapitalization textCapitalization;

  /// Больше одной строки — поле многострочное и растёт вместе с текстом.
  final int minLines;

  @override
  Widget build(BuildContext context) {
    final isMultiline = minLines > 1;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Appearance.hairline),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Fonts.label),
        const SizedBox(height: 10),
        TextField(
          keyboardType: isMultiline ? TextInputType.multiline : keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          textInputAction: isMultiline ? TextInputAction.newline : TextInputAction.next,
          minLines: minLines,
          maxLines: isMultiline ? null : 1,
          keyboardAppearance: Brightness.dark,
          style: Fonts.body,
          cursorColor: Appearance.accent,
          cursorWidth: 2,
          cursorHeight: 22,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Appearance.surfaceRaised,
            hintText: hint,
            hintStyle: Fonts.body.copyWith(color: Appearance.grey),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isMultiline ? 16 : 15),
            enabledBorder: border,
            focusedBorder: border.copyWith(borderSide: const BorderSide(color: Color(0x99FFFFFF), width: 1.5)),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
