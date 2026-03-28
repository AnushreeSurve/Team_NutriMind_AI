// lib/providers/checkin_provider.dart
import 'package:flutter/material.dart';
import '../api/api.dart';
import '../models/user_model.dart';

class CheckinProvider extends ChangeNotifier {
  CheckinResult? _lastCheckin;
  bool _isLoading = false;
  String? _error;
  bool _checkinDone = false;
  int? _lastCheckinHeartRate;        // ← stores HR for InsightsScreen graph

  CheckinResult? get lastCheckin        => _lastCheckin;
  bool get isLoading                    => _isLoading;
  String? get error                     => _error;
  bool get checkinDone                  => _checkinDone;
  int? get lastCheckinHeartRate         => _lastCheckinHeartRate;

  void reset() {
    _lastCheckin          = null;
    _checkinDone          = false;
    _error                = null;
    _isLoading            = false;
    _lastCheckinHeartRate = null;     // ← reset HR too
    notifyListeners();
  }

  Future<bool> submitCheckin({
    required String userId,
    required String date,
    required int heartRate,
    required String sleepQuality,
    required String energyLevel,
    required String mood,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.morningCheckin({
        'user_id':       userId,
        'date':          date,
        'heart_rate':    heartRate,
        'sleep_quality': sleepQuality,
        'energy_level':  energyLevel,
        'mood':          mood,
      });

      if (res['metabolic_state'] != null || res['status'] == 'success') {
        _lastCheckin          = CheckinResult.fromJson(res);
        _lastCheckinHeartRate = heartRate;   // ← store HR from checkin
        _checkinDone          = true;
        _isLoading            = false;
        notifyListeners();
        return true;
      } else {
        final detail = res['detail'];
        if (detail is List && detail.isNotEmpty) {
          _error = detail[0]['msg']?.toString() ?? 'Check-in failed';
        } else {
          _error = detail?.toString()
              ?? res['message']?.toString()
              ?? 'Check-in failed';
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error     = 'Connection error during check-in';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void setCheckinDone(bool done) {
    _checkinDone = done;
    notifyListeners();
  }
}