/// PPG service — calls backend PPG endpoints.
library;

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';

class PpgRepository {
  final ApiClient _client;

  PpgRepository({ApiClient? client}) : _client = client ?? ApiClient();

  /// POST /ppg/analyze
  Future<Map<String, dynamic>> analyze({
    required List<double> timestamps,
    required List<double> rChannel,
    required List<double> gChannel,
    double? priorBpm,
  }) async {
    return await _client.post(
      ApiConstants.ppgAnalyze,
      body: {
        'timestamps': timestamps,
        'r_channel': rChannel,
        'g_channel': gChannel,
        if (priorBpm != null) 'prior_bpm': priorBpm,
      },
    );
  }

  /// POST /ppg/submit-reading
  Future<Map<String, dynamic>> submitReading({
    required String email,
    required List<double> timestamps,
    required List<double> rChannel,
    required List<double> gChannel,
    double? priorBpm,
  }) async {
    return await _client.post(
      ApiConstants.ppgSubmitReading,
      body: {
        'email': email,
        'timestamps': timestamps,
        'r_channel': rChannel,
        'g_channel': gChannel,
        if (priorBpm != null) 'prior_bpm': priorBpm,
      },
    );
  }
}
