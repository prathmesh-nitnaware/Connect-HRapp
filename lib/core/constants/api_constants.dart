import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConstants {
  ApiConstants._();

  /// Determine appropriate base URL based on running platform
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/';
    }
    try {
      if (Platform.isAndroid) {
        // 10.0.2.2 is the default alias for the host loopback interface in Android Emulator
        return 'http://10.0.2.2:5000/api/';
      }
    } catch (_) {
      // Platform check may fail on non-supported targets
    }
    return 'http://localhost:5000/api/';
  }

  // Endpoints
  static const String loginEndpoint = 'auth/login';
  static const String signupEndpoint = 'auth/signup';
  static const String profileEndpoint = 'employee/profile';
  static const String attendanceEndpoint = 'attendance';
  static const String leaveEndpoint = 'leave';

  static const String hrEmployeesEndpoint = 'hr/employees';
  static const String hrLeavesEndpoint = 'hr/leaves';
  static const String hrAttendanceEndpoint = 'hr/attendance';
  static const String hrAnalyticsEndpoint = 'hr/analytics';

  // 1. Payroll
  static const String payrollMyPayslips = 'payroll/my-payslips';
  static const String payrollAll = 'payroll/all';
  static const String payrollGenerate = 'payroll/generate';
  static const String payrollStructure = 'payroll/structure';

  // 2. Smart Attendance (Geofencing / QR / Stats)
  static const String attendanceStats = 'employee/work-hours-stats';
  static const String qrGenerate = 'employee/qr-code';

  // 3. Announcements
  static const String announcementsEndpoint = 'announcements';

  // 4. Expenses
  static const String expensesEndpoint = 'expenses';

  // 5. Helpdesk & Tickets
  static const String ticketsEndpoint = 'tickets';

  // 6. Document Vault & Assets
  static const String vaultDocuments = 'vault/documents';
  static const String vaultAssets = 'vault/assets';

  // 7. Advanced Analytics & CSV Exports
  static const String reportsAnalytics = 'reports/advanced-analytics';
  static const String reportsExportAttendance = 'reports/export-attendance';
  static const String reportsExportLeaves = 'reports/export-leaves';

  // 8. Notifications
  static const String notificationsEndpoint = 'notifications';
}

