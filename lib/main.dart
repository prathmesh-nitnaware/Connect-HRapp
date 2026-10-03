import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routes/app_routes.dart';
import 'core/services/session_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/employee_provider.dart';
import 'providers/hr_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/payroll_provider.dart';
import 'providers/announcement_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/ticket_provider.dart';
import 'providers/document_asset_provider.dart';
import 'providers/advanced_analytics_provider.dart';
import 'providers/notification_provider.dart';

import 'screens/landing/landing_screen.dart';
import 'screens/auth/employee_login_screen.dart';
import 'screens/auth/hr_login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/employee/employee_dashboard_screen.dart';
import 'screens/hr/hr_dashboard_screen.dart';
import 'screens/hr/hr_employees_screen.dart';
import 'screens/hr/hr_leaves_screen.dart';
import 'screens/hr/hr_attendance_screen.dart';
import 'screens/payroll/payroll_screen.dart';
import 'screens/attendance/smart_attendance_screen.dart';
import 'screens/announcements/announcements_screen.dart';
import 'screens/expenses/expenses_screen.dart';
import 'screens/helpdesk/helpdesk_screen.dart';
import 'screens/vault/document_vault_screen.dart';
import 'screens/analytics/analytics_screen.dart';
import 'screens/notifications/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sessionService = SessionService();
  await sessionService.init();

  final themeProvider = ThemeProvider();
  await themeProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: sessionService),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => HRProvider()),
        ChangeNotifierProvider(create: (_) => PayrollProvider()),
        ChangeNotifierProvider(create: (_) => AnnouncementProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
        ChangeNotifierProvider(create: (_) => DocumentAssetProvider()),
        ChangeNotifierProvider(create: (_) => AdvancedAnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const ConnectHRApp(),
    ),
  );
}

class ConnectHRApp extends StatelessWidget {
  const ConnectHRApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final sessionService = context.watch<SessionService>();

    // Initial route resolution based on persisted authentication session
    String initialRoute = AppRoutes.landing;
    if (sessionService.isAuthenticated) {
      initialRoute = sessionService.isHR
          ? AppRoutes.hrDashboard
          : AppRoutes.employeeDashboard;
    }

    return MaterialApp(
      title: 'Connect HR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: initialRoute,
      routes: {
        AppRoutes.landing: (context) => const LandingScreen(),
        AppRoutes.employeeLogin: (context) => const EmployeeLoginScreen(),
        AppRoutes.hrLogin: (context) => const HRLoginScreen(),
        AppRoutes.signup: (context) => const SignupScreen(),
        AppRoutes.employeeDashboard: (context) => const EmployeeDashboardScreen(),
        AppRoutes.hrDashboard: (context) => const HRDashboardScreen(),
        AppRoutes.hrEmployees: (context) => const HREmployeesScreen(),
        AppRoutes.hrLeaves: (context) => const HRLeavesScreen(),
        AppRoutes.hrAttendance: (context) => const HRAttendanceScreen(),
        AppRoutes.payroll: (context) => const PayrollScreen(),
        AppRoutes.smartAttendance: (context) => const SmartAttendanceScreen(),
        AppRoutes.announcements: (context) => const AnnouncementsScreen(),
        AppRoutes.expenses: (context) => const ExpensesScreen(),
        AppRoutes.helpdesk: (context) => const HelpdeskScreen(),
        AppRoutes.documentVault: (context) => const DocumentVaultScreen(),
        AppRoutes.analytics: (context) => const AnalyticsScreen(),
        AppRoutes.notifications: (context) => const NotificationsScreen(),
      },
    );
  }
}
