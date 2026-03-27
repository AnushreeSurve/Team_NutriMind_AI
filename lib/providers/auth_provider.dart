// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api.dart';

class AuthProvider extends ChangeNotifier {
  String? _userId;
  String? _email;
  String? _name;

  // Temporarily holds name+email from signup screen
  // until onboarding completes and full signup is sent
  String? pendingName;
  String? pendingEmail;

  bool _onboardingComplete = false;
  bool _isLoading = false;
  String? _error;

  String? get userId => _userId;
  String? get email  => _email;
  String? get name   => _name;
  bool get onboardingComplete => _onboardingComplete;
  bool get isLoading => _isLoading;
  String? get error  => _error;
  bool get isLoggedIn => _userId != null;

  AuthProvider() {
    _loadFromPrefs();
  }

  String _extractError(Map<String, dynamic> res, String fallback) {
    final detail = res['detail'];
    final message = res['message'];
    if (message != null && message is String) return message;
    if (detail == null) return fallback;
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      final first = detail[0];
      if (first is Map) return first['msg']?.toString() ?? detail.toString();
      return detail.toString();
    }
    return detail.toString();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('Connection refused')) {
      return 'Cannot reach server. Check your internet connection.';
    } else if (msg.contains('HandshakeException')) {
      return 'Secure connection failed. Try again.';
    } else if (msg.contains('FormatException')) {
      return 'Unexpected server response. Please try again.';
    }
    return 'Error: $msg';
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    _email  = prefs.getString('user_email');
    _name   = prefs.getString('user_name');
    _onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    notifyListeners();
  }

  // Step 1 — just store name+email, navigate to onboarding
  void startSignup(String name, String email) {
    pendingName  = name;
    pendingEmail = email;
    _error = null;
    notifyListeners();
  }

  // Step 2 — called from onboarding screen with all health fields
  Future<bool> completeSignup({
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required String goal,
    required String dietType,
    required String activityLevel,
    required String budget,
  }) async {
    if (pendingName == null || pendingEmail == null) {
      _error = 'Session expired. Please sign up again.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.register(
        name: pendingName!,
        email: pendingEmail!,
        age: age,
        gender: gender,
        heightCm: heightCm,
        weightKg: weightKg,
        goal: goal,
        dietType: dietType,
        activityLevel: activityLevel,
        budget: budget,
      );

      if (res['user_id'] != null || res['status'] == 'success') {
        await _saveSession(res, pendingEmail!);
        pendingName  = null;
        pendingEmail = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = _extractError(res, 'Registration failed');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login — backend uses email+"_nutrisync" as password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.login(email: email);
      if (res['status'] == 'success' || res['user_id'] != null) {
        await _saveSession(res, email);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = _extractError(res, 'Login failed');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _saveSession(Map<String, dynamic> res, String email) async {
    final prefs = await SharedPreferences.getInstance();
    _userId = res['user_id']?.toString() ?? '';
    _email  = email;
    _name   = res['name']?.toString() ?? '';
    _onboardingComplete = res['onboarding_complete'] ?? true;
    await prefs.setString('user_id',           _userId!);
    await prefs.setString('user_email',        _email!);
    await prefs.setString('user_name',         _name!);
    await prefs.setBool('onboarding_complete', _onboardingComplete);
  }

  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingComplete = true;
    await prefs.setBool('onboarding_complete', true);
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _userId = null;
    _email  = null;
    _name   = null;
    _onboardingComplete = false;
    notifyListeners();
  }
}