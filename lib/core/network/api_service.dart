import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../services/session_service.dart';
import 'api_exception.dart';
import '../../models/auth_models.dart';
import '../../models/profile_model.dart';
import '../../models/attendance_model.dart';
import '../../models/leave_model.dart';
import '../../models/employee_model.dart';
import '../../models/analytics_model.dart';
import '../../models/payroll_model.dart';
import '../../models/announcement_model.dart';
import '../../models/expense_model.dart';
import '../../models/ticket_model.dart';
import '../../models/document_asset_model.dart';
import '../../models/advanced_analytics_model.dart';
import '../../models/notification_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final SessionService _sessionService = SessionService();

  String get baseUrl {
    final customUrl = _sessionService.customBaseUrl;
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      return customUrl.endsWith('/') ? customUrl : '$customUrl/';
    }
    return ApiConstants.defaultBaseUrl;
  }

  Map<String, String> _getHeaders({String? token, bool isJson = true}) {
    final headers = <String, String>{
      if (isJson) 'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final authToken = token ?? _sessionService.token;
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = authToken.startsWith('Bearer ')
          ? authToken
          : 'Bearer $authToken';
    }

    return headers;
  }

  dynamic _processResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String errorMessage = 'Request failed with status: ${response.statusCode}';
    if (body is Map<String, dynamic> && body.containsKey('message')) {
      errorMessage = body['message'].toString();
    } else if (body is String && body.isNotEmpty) {
      errorMessage = body;
    }

    throw ApiException(errorMessage, response.statusCode);
  }

  // --- Auth Endpoints ---

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.loginEndpoint}');
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(request.toJson()),
      );
      final data = _processResponse(response);
      return LoginResponse.fromJson(data as Map<String, dynamic>);
    } on SocketException catch (e) {
      throw ApiException('Cannot connect to server. Check network / base URL (${e.message})');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<SignupResponse> signup(SignupRequest request) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.signupEndpoint}');
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(request.toJson()),
      );
      final data = _processResponse(response);
      return SignupResponse.fromJson(data as Map<String, dynamic>);
    } on SocketException catch (e) {
      throw ApiException('Cannot connect to server. (${e.message})');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  // --- Employee Profile & Attendance ---

  Future<ProfileResponse> getProfile({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.profileEndpoint}');
      final response = await http.get(
        url,
        headers: _getHeaders(token: token),
      );
      final data = _processResponse(response);
      return ProfileResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<AttendanceResponse> punchAttendance(AttendanceRequest request, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.attendanceEndpoint}');
      final response = await http.post(
        url,
        headers: _getHeaders(token: token),
        body: jsonEncode(request.toJson()),
      );
      final data = _processResponse(response);
      return AttendanceResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<List<AttendanceHistory>> getAttendanceHistory({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.attendanceEndpoint}');
      final response = await http.get(
        url,
        headers: _getHeaders(token: token),
      );
      final data = _processResponse(response);
      if (data is List) {
        return data.map((item) => AttendanceHistory.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<LeaveResponse> applyLeave(LeaveRequest request, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.leaveEndpoint}');
      final response = await http.post(
        url,
        headers: _getHeaders(token: token),
        body: jsonEncode(request.toJson()),
      );
      final data = _processResponse(response);
      return LeaveResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<List<LeaveRequest>> getLeaveHistory({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.leaveEndpoint}');
      final response = await http.get(
        url,
        headers: _getHeaders(token: token),
      );
      final data = _processResponse(response);
      if (data is List) {
        return data.map((item) => LeaveRequest(
          leaveType: item['leave_type'] ?? '',
          reason: item['reason'] ?? '',
          date: item['date'] ?? '',
        )).toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  // --- 2. Smart Attendance & Overtime ---

  Future<Map<String, dynamic>> getWorkHoursStats({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.attendanceStats}');
      final response = await http.get(url, headers: _getHeaders(token: token));
      final data = _processResponse(response);
      return data as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> getOfficeQrCode({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.qrGenerate}');
      final response = await http.get(url, headers: _getHeaders(token: token));
      final data = _processResponse(response);
      return data as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  // --- 1. Payroll & Payslip Management ---

  Future<List<Payslip>> getMyPayslips({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.payrollMyPayslips}');
      final response = await http.get(url, headers: _getHeaders(token: token));
      final data = _processResponse(response);
      if (data is List) {
        return data.map((item) => Payslip.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<List<Payslip>> getAllPayslips({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.payrollAll}');
      final response = await http.get(url, headers: _getHeaders(token: token));
      final data = _processResponse(response);
      if (data is List) {
        return data.map((item) => Payslip.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<SalaryStructure> getSalaryStructure({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.payrollStructure}');
      final response = await http.get(url, headers: _getHeaders(token: token));
      final data = _processResponse(response);
      return SalaryStructure.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<Payslip> generatePayslip(Map<String, dynamic> payload, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.payrollGenerate}');
      final response = await http.post(
        url,
        headers: _getHeaders(token: token),
        body: jsonEncode(payload),
      );
      final data = _processResponse(response);
      return Payslip.fromJson(data['payslip'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  // --- 3. Company Announcements ---

  Future<List<Announcement>> getAnnouncements({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.announcementsEndpoint}');
      final response = await http.get(url, headers: _getHeaders(token: token));
      final data = _processResponse(response);
      if (data is List) {
        return data.map((item) => Announcement.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<Announcement> createAnnouncement(Map<String, dynamic> payload, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.announcementsEndpoint}');
      final response = await http.post(
        url,
        headers: _getHeaders(token: token),
        body: jsonEncode(payload),
      );
      final data = _processResponse(response);
      return Announcement.fromJson(data['announcement'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<void> markAnnouncementRead(String id, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.announcementsEndpoint}/$id/read');
      final response = await http.post(url, headers: _getHeaders(token: token));
      _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<void> deleteAnnouncement(String id, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.announcementsEndpoint}/$id');
      final response = await http.delete(url, headers: _getHeaders(token: token));
      _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  // --- 4. Expense Claims ---

  Future<List<ExpenseClaim>> getMyExpenses({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.expensesEndpoint}/my');
      final response = await http.get(url, headers: _getHeaders(token: token));
      final data = _processResponse(response);
      if (data is List) {
        return data.map((item) => ExpenseClaim.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<List<ExpenseClaim>> getAllExpenses({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.expensesEndpoint}/all');
      final response = await http.get(url, headers: _getHeaders(token: token));
      final data = _processResponse(response);
      if (data is List) {
        return data.map((item) => ExpenseClaim.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<ExpenseClaim> submitExpense(Map<String, dynamic> payload, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.expensesEndpoint}');
      final response = await http.post(
        url,
        headers: _getHeaders(token: token),
        body: jsonEncode(payload),
      );
      final data = _processResponse(response);
      return ExpenseClaim.fromJson(data['expense'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<void> updateExpenseStatus(String id, String status, {String? comment, String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.expensesEndpoint}/$id/status');
      final response = await http.put(
        url,
        headers: _getHeaders(token: token),
        body: jsonEncode({'status': status, 'comment': comment ?? ''}),
      );
      _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  // --- 5. HR Helpdesk & Ticketing ---

  Future<List<HelpdeskTicket>> getMyTickets({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.ticketsEndpoint}/my');
      final response = await http.get(url, headers: _getHeaders(token: token));
      final data = _processResponse(response);
      if (data is List) {
        return data.map((item) => HelpdeskTicket.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<List<HelpdeskTicket>> getAllTickets({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.ticketsEndpoint}/all');
      final response = await http.get(url, headers: _getHeaders(token: token));
      final data = _processResponse(response);
      if (data is List) {
        return data.map((item) => HelpdeskTicket.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<HelpdeskTicket> createTicket(Map<String, dynamic> payload, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.ticketsEndpoint}');
      final response = await http.post(
        url,
        headers: _getHeaders(token: token),
        body: jsonEncode(payload),
      );
      final data = _processResponse(response);
      return HelpdeskTicket.fromJson(data['ticket'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<void> addTicketMessage(String id, String message, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.ticketsEndpoint}/$id/messages');
      final response = await http.post(
        url,
        headers: _getHeaders(token: token),
        body: jsonEncode({'message': message}),
      );
      _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<void> updateTicketStatus(String id, String status, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.ticketsEndpoint}/$id/status');
      final response = await http.put(
        url,
        headers: _getHeaders(token: token),
        body: jsonEncode({'status': status}),
      );
      _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  // --- 6. Document Vault & Assets ---

  Future<List<VaultDocument>> getMyDocuments({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.vaultDocuments}');
      final response = await http.get(url, headers: _getHeaders(token: token));
      final data = _processResponse(response);
      if (data is List) {
        return data.map((item) => VaultDocument.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<VaultDocument> uploadDocument(Map<String, dynamic> payload, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.vaultDocuments}');
      final response = await http.post(
        url,
        headers: _getHeaders(token: token),
        body: jsonEncode(payload),
      );
      final data = _processResponse(response);
      return VaultDocument.fromJson(data['document'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<List<CompanyAsset>> getMyAssets({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.vaultAssets}/my');
      final response = await http.get(url, headers: _getHeaders(token: token));
      final data = _processResponse(response);
      if (data is List) {
        return data.map((item) => CompanyAsset.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<List<CompanyAsset>> getAllAssets({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.vaultAssets}/all');
      final response = await http.get(url, headers: _getHeaders(token: token));
      final data = _processResponse(response);
      if (data is List) {
        return data.map((item) => CompanyAsset.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<CompanyAsset> assignAsset(Map<String, dynamic> payload, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.vaultAssets}');
      final response = await http.post(
        url,
        headers: _getHeaders(token: token),
        body: jsonEncode(payload),
      );
      final data = _processResponse(response);
      return CompanyAsset.fromJson(data['asset'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  // --- 7. Advanced Analytics & CSV Reports ---

  Future<AdvancedHRAnalytics> getAdvancedAnalytics({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.reportsAnalytics}');
      final response = await http.get(url, headers: _getHeaders(token: token));
      final data = _processResponse(response);
      return AdvancedHRAnalytics.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<String> exportAttendanceCsv({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.reportsExportAttendance}');
      final response = await http.get(url, headers: _getHeaders(token: token, isJson: false));
      return response.body;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<String> exportLeavesCsv({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.reportsExportLeaves}');
      final response = await http.get(url, headers: _getHeaders(token: token, isJson: false));
      return response.body;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  // --- 8. Push Notifications & Reminders ---

  Future<List<AppNotification>> getNotifications({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.notificationsEndpoint}');
      final response = await http.get(url, headers: _getHeaders(token: token));
      final data = _processResponse(response);
      if (data is List) {
        return data.map((item) => AppNotification.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<void> markNotificationRead(String id, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.notificationsEndpoint}/$id/read');
      final response = await http.put(url, headers: _getHeaders(token: token));
      _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<void> markAllNotificationsRead({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.notificationsEndpoint}/read-all');
      final response = await http.put(url, headers: _getHeaders(token: token));
      _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  // --- Existing HR Endpoints ---

  Future<HRAnalyticsResponse> getHRAnalytics({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.hrAnalyticsEndpoint}');
      final response = await http.get(
        url,
        headers: _getHeaders(token: token),
      );
      final data = _processResponse(response);
      return HRAnalyticsResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<List<HREmployee>> getHREmployees({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.hrEmployeesEndpoint}');
      final response = await http.get(
        url,
        headers: _getHeaders(token: token),
      );
      final data = _processResponse(response);
      if (data is List) {
        return data.map((item) => HREmployee.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<SignupResponse> createHREmployee(SignupRequest request, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.hrEmployeesEndpoint}');
      final response = await http.post(
        url,
        headers: _getHeaders(token: token),
        body: jsonEncode(request.toJson()),
      );
      final data = _processResponse(response);
      return SignupResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<SignupResponse> updateHREmployee(String id, HREmployeeUpdateRequest request, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.hrEmployeesEndpoint}/$id');
      final response = await http.put(
        url,
        headers: _getHeaders(token: token),
        body: jsonEncode(request.toJson()),
      );
      final data = _processResponse(response);
      return SignupResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<SignupResponse> deleteHREmployee(String id, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.hrEmployeesEndpoint}/$id');
      final response = await http.delete(
        url,
        headers: _getHeaders(token: token),
      );
      final data = _processResponse(response);
      return SignupResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<List<HRLeave>> getHRLeaves({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.hrLeavesEndpoint}');
      final response = await http.get(
        url,
        headers: _getHeaders(token: token),
      );
      final data = _processResponse(response);
      if (data is List) {
        return data.map((item) => HRLeave.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<SignupResponse> updateHRLeave(String id, HRLeaveUpdateRequest request, {String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.hrLeavesEndpoint}/$id');
      final response = await http.put(
        url,
        headers: _getHeaders(token: token),
        body: jsonEncode(request.toJson()),
      );
      final data = _processResponse(response);
      return SignupResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<List<HRAttendanceRecord>> getHRAttendance({String? token}) async {
    try {
      final url = Uri.parse('$baseUrl${ApiConstants.hrAttendanceEndpoint}');
      final response = await http.get(
        url,
        headers: _getHeaders(token: token),
      );
      final data = _processResponse(response);
      if (data is List) {
        return data.map((item) => HRAttendanceRecord.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }
}
