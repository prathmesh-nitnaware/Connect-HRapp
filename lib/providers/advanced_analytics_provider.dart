import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../models/advanced_analytics_model.dart';

class AdvancedAnalyticsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  AdvancedHRAnalytics? _analytics;
  bool _isLoading = false;
  String? _errorMessage;

  AdvancedHRAnalytics? get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAdvancedAnalytics({String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _analytics = await _apiService.getAdvancedAnalytics(token: token);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> exportAttendanceCsv({String? token}) async {
    try {
      return await _apiService.exportAttendanceCsv(token: token);
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  Future<String?> exportLeavesCsv({String? token}) async {
    try {
      return await _apiService.exportLeavesCsv(token: token);
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }
}
