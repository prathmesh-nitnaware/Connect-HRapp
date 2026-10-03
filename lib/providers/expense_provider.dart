import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../models/expense_model.dart';

class ExpenseProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<ExpenseClaim> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ExpenseClaim> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyExpenses({String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _expenses = await _apiService.getMyExpenses(token: token);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllExpenses({String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _expenses = await _apiService.getAllExpenses(token: token);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitExpense(Map<String, dynamic> payload, {String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final item = await _apiService.submitExpense(payload, token: token);
      _expenses.insert(0, item);
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

  Future<bool> updateStatus(String id, String status, {String? comment, String? token}) async {
    try {
      await _apiService.updateExpenseStatus(id, status, comment: comment, token: token);
      final index = _expenses.indexWhere((e) => e.id == id);
      if (index != -1) {
        final old = _expenses[index];
        _expenses[index] = ExpenseClaim(
          id: old.id,
          employeeId: old.employeeId,
          employeeName: old.employeeName,
          title: old.title,
          category: old.category,
          amount: old.amount,
          date: old.date,
          receiptUrl: old.receiptUrl,
          status: status,
          reviewerComment: comment ?? old.reviewerComment,
          createdAt: old.createdAt,
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
