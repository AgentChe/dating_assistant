import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Выбор скриншота переписки из галереи — системный пикер фото, доступ к библиотеке ему не нужен.
class ScreenshotPicker {
  /// JPEG скриншота или null, если пользователь ничего не выбрал.
  ///
  /// Ограничение размера с запасом: обычный скриншот iPhone (1290×2796) не уменьшается, текст остаётся читаемым.
  Future<Uint8List?> pick() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 4000,
      imageQuality: 90,
    );
    return file?.readAsBytes();
  }
}
