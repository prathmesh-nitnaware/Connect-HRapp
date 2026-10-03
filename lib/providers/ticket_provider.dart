import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../models/ticket_model.dart';

class TicketProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<HelpdeskTicket> _tickets = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<HelpdeskTicket> get tickets => _tickets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyTickets({String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tickets = await _apiService.getMyTickets(token: token);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllTickets({String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tickets = await _apiService.getAllTickets(token: token);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTicket(Map<String, dynamic> payload, {String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ticket = await _apiService.createTicket(payload, token: token);
      _tickets.insert(0, ticket);
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

  Future<bool> sendMessage(String ticketId, String message, String senderId, String senderName, String role, {String? token}) async {
    try {
      await _apiService.addTicketMessage(ticketId, message, token: token);
      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        _tickets[index].messages.add(
          TicketMessage(
            senderId: senderId,
            senderName: senderName,
            senderRole: role,
            message: message,
            timestamp: DateTime.now().toIso8601String(),
          ),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> updateStatus(String ticketId, String status, {String? token}) async {
    try {
      await _apiService.updateTicketStatus(ticketId, status, token: token);
      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        final old = _tickets[index];
        _tickets[index] = HelpdeskTicket(
          id: old.id,
          employeeId: old.employeeId,
          employeeName: old.employeeName,
          subject: old.subject,
          category: old.category,
          priority: old.priority,
          status: status,
          createdAt: old.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
          messages: old.messages,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }
}
