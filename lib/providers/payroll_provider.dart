import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../models/payroll_model.dart';

class PayrollProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Payslip> _payslips = [];
  SalaryStructure? _salaryStructure;
  bool _isLoading = false;
  String? _errorMessage;

  List<Payslip> get payslips => _payslips;
  SalaryStructure? get salaryStructure => _salaryStructure;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyPayslips({String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _payslips = await _apiService.getMyPayslips(token: token);
      _salaryStructure = await _apiService.getSalaryStructure(token: token);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllPayslips({String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _payslips = await _apiService.getAllPayslips(token: token);
      _salaryStructure = await _apiService.getSalaryStructure(token: token);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSalaryStructure({String? token}) async {
    try {
      _salaryStructure = await _apiService.getSalaryStructure(token: token);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> generatePayslip(Map<String, dynamic> payload, {String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final slip = await _apiService.generatePayslip(payload, token: token);
      _payslips.removeWhere((p) => p.id == slip.id);
      _payslips.insert(0, slip);
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
}
