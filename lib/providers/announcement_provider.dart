import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../models/announcement_model.dart';

class AnnouncementProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Announcement> _announcements = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Announcement> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAnnouncements({String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _announcements = await _apiService.getAnnouncements(token: token);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAnnouncement(Map<String, dynamic> payload, {String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final item = await _apiService.createAnnouncement(payload, token: token);
      _announcements.insert(0, item);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> markAsRead(String id, String userId, {String? token}) async {
    try {
      await _apiService.markAnnouncementRead(id, token: token);
      final index = _announcements.indexWhere((a) => a.id == id);
      if (index != -1) {
        if (!_announcements[index].readBy.contains(userId)) {
          _announcements[index].readBy.add(userId);
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<bool> deleteAnnouncement(String id, {String? token}) async {
    try {
      await _apiService.deleteAnnouncement(id, token: token);
      _announcements.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }
}
