/// Health feature — repository for health plan endpoint.
library;

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';

class HealthRepository {
  final ApiClient _client;

  HealthRepository({ApiClient? client}) : _client = client ?? ApiClient();

  /// POST /health/health-plan
  Future<Map<String, dynamic>> getHealthPlan(
      String email, String condition) async {
    return await _client.post(
      ApiConstants.healthPlan,
      body: {'email': email, 'condition': condition},
    );
  }
}
