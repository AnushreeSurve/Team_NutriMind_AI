/// Profile repository — calls preferences endpoints.
library;

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';

class ProfileRepository {
  final ApiClient _client;

  ProfileRepository({ApiClient? client}) : _client = client ?? ApiClient();

  /// POST /user/get-preferences
  Future<Map<String, dynamic>> getPreferences(String email) async {
    try {
      return await _client.post(
        ApiConstants.getPreferences,
        body: {'email': email},
      );
    } catch (_) {
      return {
        'diet_type': 'veg',
        'budget': 'mid',
        'allergies': <String>[],
        'conditions': <String>[],
      };
    }
  }

  /// POST /user/set-preferences
  Future<Map<String, dynamic>> setPreferences({
    required String email,
    required String dietType,
    required String budget,
    required List<String> allergies,
    required List<String> conditions,
  }) async {
    return await _client.post(
      ApiConstants.setPreferences,
      body: {
        'email': email,
        'diet_type': dietType,
        'budget': budget,
        'allergies': allergies,
        'conditions': conditions,
      },
    );
  }
}
