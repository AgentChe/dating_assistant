import 'dart:convert';
import 'dart:typed_data';

import 'package:dating_assistant/transport/api_request.dart';

/// Разобрать переписку по скриншоту. Сервер не хранит картинку: в истории остаётся только разбор.
class AnalyzeScreenshotRequest extends ApiRequest {
  const AnalyzeScreenshotRequest(this.screenshot);

  /// JPEG скриншота.
  final Uint8List screenshot;

  @override
  String get path => '/api/v1/analyses';

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  Map<String, dynamic> get body => {'screenshot': base64Encode(screenshot)};
}
