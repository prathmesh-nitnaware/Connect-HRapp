import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<AppNotification> _notifications = [];
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications({String? token}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _apiService.getNotifications(token: token);
    } catch (_) {
      // Gracefully handle or ignore
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id, {String? token}) async {
    try {
      await _apiService.markNotificationRead(id, token: token);
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead({String? token}) async {
    try {
      await _apiService.markAllNotificationsRead(token: token);
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
    } catch (_) {}
  }
}
