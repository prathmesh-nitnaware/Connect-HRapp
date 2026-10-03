import 'dart:io';
import 'package:connect_hr_server/config/server_config.dart';
import 'package:connect_hr_server/controllers/analytics_controller.dart';
import 'package:connect_hr_server/controllers/announcement_controller.dart';
import 'package:connect_hr_server/controllers/auth_controller.dart';
import 'package:connect_hr_server/controllers/document_asset_controller.dart';
import 'package:connect_hr_server/controllers/employee_controller.dart';
import 'package:connect_hr_server/controllers/expense_controller.dart';
import 'package:connect_hr_server/controllers/hr_controller.dart';
import 'package:connect_hr_server/controllers/notification_controller.dart';
import 'package:connect_hr_server/controllers/payroll_controller.dart';
import 'package:connect_hr_server/controllers/ticket_controller.dart';
import 'package:connect_hr_server/db/database_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

void main(List<String> args) async {
  // Initialize configuration
  final config = ServerConfig()..init();

  // Initialize Database
  final db = DatabaseService();
  await db.connect();

  final appRouter = Router();

  final authController = AuthController();
  final employeeController = EmployeeController();
  final hrController = HRController();
  final payrollController = PayrollController();
  final announcementController = AnnouncementController();
  final expenseController = ExpenseController();
  final ticketController = TicketController();
  final documentAssetController = DocumentAssetController();
  final analyticsController = AnalyticsController();
  final notificationController = NotificationController();

  // Core Auth & Profile
  appRouter.mount('/api/auth/', authController.router.call);
  appRouter.mount('/api/auth', authController.router.call);
  appRouter.mount('/api/employee/', employeeController.router.call);
  appRouter.mount('/api/employee', employeeController.router.call);
  
  // Attendance & Leaves
  appRouter.post('/api/attendance', employeeController.handlePostAttendance);
  appRouter.get('/api/attendance', employeeController.handleGetAttendance);
  appRouter.post('/api/leave', employeeController.handlePostLeave);
  appRouter.get('/api/leave', employeeController.handleGetLeave);

  // New Enterprise Feature Modules
  appRouter.mount('/api/payroll/', payrollController.router.call);
  appRouter.mount('/api/payroll', payrollController.router.call);
  appRouter.mount('/api/announcements/', announcementController.router.call);
  appRouter.mount('/api/announcements', announcementController.router.call);
  appRouter.mount('/api/expenses/', expenseController.router.call);
  appRouter.mount('/api/expenses', expenseController.router.call);
  appRouter.mount('/api/tickets/', ticketController.router.call);
  appRouter.mount('/api/tickets', ticketController.router.call);
  appRouter.mount('/api/vault/', documentAssetController.router.call);
  appRouter.mount('/api/vault', documentAssetController.router.call);
  appRouter.mount('/api/reports/', analyticsController.router.call);
  appRouter.mount('/api/reports', analyticsController.router.call);
  appRouter.mount('/api/notifications/', notificationController.router.call);
  appRouter.mount('/api/notifications', notificationController.router.call);

  // HR Routes
  appRouter.mount('/api/hr/', hrController.router.call);
  appRouter.mount('/api/hr', hrController.router.call);


  // Health check
  appRouter.get('/health', (Request req) {
    return Response.ok('{"status": "ok", "service": "connect-hr-server", "version": "2.0.0"}', headers: {'content-type': 'application/json'});
  });

  // Pipeline configuration with logging and CORS
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders(
        headers: {
          ACCESS_CONTROL_ALLOW_ORIGIN: '*',
          ACCESS_CONTROL_ALLOW_METHODS: 'GET, POST, PUT, DELETE, OPTIONS',
          ACCESS_CONTROL_ALLOW_HEADERS: 'Origin, Content-Type, Accept, Authorization',
        },
      ))
      .addHandler(appRouter.call);

  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? config.port;
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);

  // Startup banner
  stdout.writeln('🚀 Connect HR Full-Stack Server running on http://${server.address.host}:${server.port}');
  stdout.writeln('📡 API Base URL: http://${server.address.host}:${server.port}/api/');
  stdout.writeln('🌟 Enterprise Modules: Payroll, Geofencing/QR, Notices, Expenses, Helpdesk, Vault, Analytics & Notifications');
}
