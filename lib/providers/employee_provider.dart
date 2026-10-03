import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../core/network/api_service.dart';
import '../core/network/api_exception.dart';
import '../models/profile_model.dart';
import '../models/attendance_model.dart';
import '../models/leave_model.dart';

class EmployeeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  ProfileResponse? _profile;
  List<AttendanceHistory> _attendanceHistory = [];
  List<LeaveRequest> _leaveHistory = [];

  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _statusMessage;
  bool _isSuccessMessage = true;

  ProfileResponse? get profile => _profile;
  List<AttendanceHistory> get attendanceHistory => _attendanceHistory;
  List<LeaveRequest> get leaveHistory => _leaveHistory;

  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get statusMessage => _statusMessage;
  bool get isSuccessMessage => _isSuccessMessage;

  void clearStatus() {
    _statusMessage = null;
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    try {
      _profile = await _apiService.getProfile();
      notifyListeners();
    } catch (e) {
      // Non-blocking profile load
    }
  }

  Future<void> fetchAttendanceHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _attendanceHistory = await _apiService.getAttendanceHistory();
    } catch (e) {
      _statusMessage = e.toString();
      _isSuccessMessage = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLeaveHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _leaveHistory = await _apiService.getLeaveHistory();
    } catch (e) {
      _statusMessage = e.toString();
      _isSuccessMessage = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AttendanceResponse> punchAttendance(AttendanceRequest request, {String? token}) async {
    _isActionLoading = true;
    _statusMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.punchAttendance(request, token: token);
      _statusMessage = response.message.isNotEmpty ? response.message : 'Attendance punched successfully';
      _isSuccessMessage = true;
      _isActionLoading = false;
      notifyListeners();
      await fetchAttendanceHistory();
      return response;
    } catch (e) {
      _statusMessage = e.toString();
      _isSuccessMessage = false;
      _isActionLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> punchIn() async {
    _isActionLoading = true;
    _statusMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.punchAttendance(AttendanceRequest(action: 'punch_in'));
      _statusMessage = response.message.isNotEmpty ? response.message : 'Punched in successfully';
      _isSuccessMessage = true;
      _isActionLoading = false;
      notifyListeners();
      await fetchAttendanceHistory();
      return true;
    } on ApiException catch (e) {
      _statusMessage = e.message;
      _isSuccessMessage = false;
      _isActionLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _statusMessage = 'Error: ${e.toString()}';
      _isSuccessMessage = false;
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> punchOut() async {
    _isActionLoading = true;
    _statusMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.punchAttendance(AttendanceRequest(action: 'punch_out'));
      _statusMessage = response.message.isNotEmpty ? response.message : 'Punched out successfully';
      _isSuccessMessage = true;
      _isActionLoading = false;
      notifyListeners();
      await fetchAttendanceHistory();
      return true;
    } on ApiException catch (e) {
      _statusMessage = e.message;
      _isSuccessMessage = false;
      _isActionLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _statusMessage = 'Error: ${e.toString()}';
      _isSuccessMessage = false;
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> applyLeave({
    required String leaveType,
    required String reason,
    String? date,
  }) async {
    _isActionLoading = true;
    _statusMessage = null;
    notifyListeners();

    final dateStr = date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final response = await _apiService.applyLeave(LeaveRequest(
        leaveType: leaveType,
        reason: reason,
        date: dateStr,
      ));
      _statusMessage = response.message.isNotEmpty ? response.message : 'Leave applied successfully';
      _isSuccessMessage = true;
      _isActionLoading = false;
      notifyListeners();
      await fetchLeaveHistory();
      return true;
    } on ApiException catch (e) {
      _statusMessage = e.message;
      _isSuccessMessage = false;
      _isActionLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _statusMessage = 'Error: ${e.toString()}';
      _isSuccessMessage = false;
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }
}
