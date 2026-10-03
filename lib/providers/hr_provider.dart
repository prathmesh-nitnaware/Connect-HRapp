import 'package:flutter/foundation.dart';
import '../core/network/api_service.dart';
import '../core/network/api_exception.dart';
import '../models/analytics_model.dart';
import '../models/employee_model.dart';
import '../models/leave_model.dart';
import '../models/attendance_model.dart';
import '../models/auth_models.dart';

class HRProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  HRAnalyticsResponse? _analytics;
  List<HREmployee> _employees = [];
  List<HRLeave> _leaves = [];
  List<HRAttendanceRecord> _attendanceRecords = [];

  bool _isLoadingAnalytics = false;
  bool _isLoadingEmployees = false;
  bool _isLoadingLeaves = false;
  bool _isLoadingAttendance = false;

  String? _statusMessage;
  bool _isSuccessMessage = true;

  HRAnalyticsResponse? get analytics => _analytics;
  List<HREmployee> get employees => _employees;
  List<HRLeave> get leaves => _leaves;
  List<HRAttendanceRecord> get attendanceRecords => _attendanceRecords;

  bool get isLoadingAnalytics => _isLoadingAnalytics;
  bool get isLoadingEmployees => _isLoadingEmployees;
  bool get isLoadingLeaves => _isLoadingLeaves;
  bool get isLoadingAttendance => _isLoadingAttendance;

  String? get statusMessage => _statusMessage;
  bool get isSuccessMessage => _isSuccessMessage;

  void clearStatus() {
    _statusMessage = null;
    notifyListeners();
  }

  // --- Analytics ---
  Future<void> fetchAnalytics() async {
    _isLoadingAnalytics = true;
    notifyListeners();

    try {
      _analytics = await _apiService.getHRAnalytics();
    } catch (e) {
      _statusMessage = 'Analytics error: ${e.toString()}';
      _isSuccessMessage = false;
    } finally {
      _isLoadingAnalytics = false;
      notifyListeners();
    }
  }

  // --- Employees ---
  Future<void> fetchEmployees() async {
    _isLoadingEmployees = true;
    _statusMessage = null;
    notifyListeners();

    try {
      _employees = await _apiService.getHREmployees();
    } on ApiException catch (e) {
      _statusMessage = e.message;
      _isSuccessMessage = false;
    } catch (e) {
      _statusMessage = 'Error: ${e.toString()}';
      _isSuccessMessage = false;
    } finally {
      _isLoadingEmployees = false;
      notifyListeners();
    }
  }

  Future<bool> createEmployee({
    required String name,
    required String email,
    required String password,
    String role = 'employee',
    String department = 'Unassigned',
  }) async {
    _statusMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.createHREmployee(SignupRequest(
        name: name.trim(),
        email: email.trim(),
        password: password,
        role: role,
        department: department,
      ));
      _statusMessage = response.message ?? 'Employee created successfully';
      _isSuccessMessage = true;
      await fetchEmployees();
      await fetchAnalytics();
      return true;
    } on ApiException catch (e) {
      _statusMessage = e.message;
      _isSuccessMessage = false;
      notifyListeners();
      return false;
    } catch (e) {
      _statusMessage = 'Error: ${e.toString()}';
      _isSuccessMessage = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEmployeeDepartment({
    required String employeeId,
    required String newDepartment,
  }) async {
    _statusMessage = null;
    notifyListeners();

    try {
      await _apiService.updateHREmployee(
        employeeId,
        HREmployeeUpdateRequest(department: newDepartment),
      );
      _employees = _employees
          .map((e) => e.id == employeeId ? e.copyWith(department: newDepartment) : e)
          .toList();
      _statusMessage = 'Department updated to $newDepartment';
      _isSuccessMessage = true;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _statusMessage = e.message;
      _isSuccessMessage = false;
      notifyListeners();
      return false;
    } catch (e) {
      _statusMessage = 'Error: ${e.toString()}';
      _isSuccessMessage = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEmployee(String employeeId) async {
    _statusMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteHREmployee(employeeId);
      _employees = _employees.where((e) => e.id != employeeId).toList();
      _statusMessage = 'Employee removed successfully';
      _isSuccessMessage = true;
      notifyListeners();
      await fetchAnalytics();
      return true;
    } on ApiException catch (e) {
      _statusMessage = e.message;
      _isSuccessMessage = false;
      notifyListeners();
      return false;
    } catch (e) {
      _statusMessage = 'Error: ${e.toString()}';
      _isSuccessMessage = false;
      notifyListeners();
      return false;
    }
  }

  // --- Leaves ---
  Future<void> fetchLeaves() async {
    _isLoadingLeaves = true;
    _statusMessage = null;
    notifyListeners();

    try {
      _leaves = await _apiService.getHRLeaves();
    } on ApiException catch (e) {
      _statusMessage = e.message;
      _isSuccessMessage = false;
    } catch (e) {
      _statusMessage = 'Error: ${e.toString()}';
      _isSuccessMessage = false;
    } finally {
      _isLoadingLeaves = false;
      notifyListeners();
    }
  }

  Future<bool> updateLeaveStatus({
    required String leaveId,
    required String status,
  }) async {
    _statusMessage = null;
    notifyListeners();

    try {
      await _apiService.updateHRLeave(
        leaveId,
        HRLeaveUpdateRequest(status: status),
      );
      _leaves = _leaves
          .map((l) => l.id == leaveId ? l.copyWith(status: status) : l)
          .toList();
      _statusMessage = 'Leave marked as $status';
      _isSuccessMessage = true;
      notifyListeners();
      await fetchAnalytics();
      return true;
    } on ApiException catch (e) {
      _statusMessage = e.message;
      _isSuccessMessage = false;
      notifyListeners();
      return false;
    } catch (e) {
      _statusMessage = 'Error: ${e.toString()}';
      _isSuccessMessage = false;
      notifyListeners();
      return false;
    }
  }

  // --- Attendance ---
  Future<void> fetchAttendance() async {
    _isLoadingAttendance = true;
    _statusMessage = null;
    notifyListeners();

    try {
      _attendanceRecords = await _apiService.getHRAttendance();
    } on ApiException catch (e) {
      _statusMessage = e.message;
      _isSuccessMessage = false;
    } catch (e) {
      _statusMessage = 'Error: ${e.toString()}';
      _isSuccessMessage = false;
    } finally {
      _isLoadingAttendance = false;
      notifyListeners();
    }
  }
}
