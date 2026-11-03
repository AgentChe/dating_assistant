import 'package:dating_assistant/transport/mock/mock_database.dart';
import 'package:dating_assistant/transport/mock/mock_request.dart';
import 'package:dating_assistant/transport/network_error.dart';

/// Моки эндпоинтов профиля.
class ProfileMockRoutes {
  ProfileMockRoutes(this._database);

  static const _profileKey = 'profile';

  final MockDatabase _database;

  Map<String, MockHandler> get routes => {
    'POST /api/v1/profile': _create,
    'GET /api/v1/profile': _obtain,
  };

  /// Создаёт анонимного пользователя по ответам онбординга → `{token, profile}`.
  Future<Map<String, dynamic>> _create(MockRequest request) async {
    final profile = {
      'gender': request.body['gender'],
      'age': request.body['age'],
      'dating_goal': request.body['dating_goal'],
    };
    await _database.write(_profileKey, profile);
    return {'token': 'mock-token-${DateTime.now().millisecondsSinceEpoch}', 'profile': profile};
  }

  /// Профиль текущего пользователя → `{profile}`.
  Map<String, dynamic> _obtain(MockRequest request) {
    final profile = _database.read(_profileKey);
    if (profile == null) {
      throw const NetworkError(NetworkErrorCode.logical, statusCode: 404, message: 'Profile not found');
    }
    return {'profile': profile};
  }
}
