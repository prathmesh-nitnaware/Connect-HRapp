import 'dart:convert';
import 'package:connect_hr_server/config/server_config.dart';
import 'package:connect_hr_server/controllers/auth_controller.dart';
import 'package:connect_hr_server/controllers/employee_controller.dart';
import 'package:connect_hr_server/controllers/hr_controller.dart';
import 'package:connect_hr_server/db/database_service.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

void main() {
  late dynamic server;
  late String baseUrl;

  setUpAll(() async {
    ServerConfig().init();
    final db = DatabaseService();
    await db.connect();

    final appRouter = Router();
    final authController = AuthController();
    final employeeController = EmployeeController();
    final hrController = HRController();

    appRouter.mount('/api/auth/', authController.router.call);
    appRouter.mount('/api/employee/', employeeController.router.call);
    appRouter.post('/api/attendance', employeeController.handlePostAttendance);
    appRouter.get('/api/attendance', employeeController.handleGetAttendance);
    appRouter.post('/api/leave', employeeController.handlePostLeave);
    appRouter.get('/api/leave', employeeController.handleGetLeave);
    appRouter.mount('/api/hr/', hrController.router.call);

    final handler = Pipeline()
        .addMiddleware(corsHeaders())
        .addHandler(appRouter.call);

    server = await io.serve(handler, 'localhost', 0);
    baseUrl = 'http://localhost:${server.port}/api';
  });

  tearDownAll(() async {
    await server.close();
  });

  test('Employee Login with seeded credentials', () async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'email': 'john@connect.com', 'password': 'password123'}),
    );

    expect(response.statusCode, equals(200));
    final data = jsonDecode(response.body);
    expect(data['token'], isNotNull);
    expect(data['role'], equals('employee'));
  });

  test('HR Login with seeded credentials', () async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'email': 'hr@connect.com', 'password': 'admin123'}),
    );

    expect(response.statusCode, equals(200));
    final data = jsonDecode(response.body);
    expect(data['token'], isNotNull);
    expect(data['role'], equals('HR'));
  });

  test('HR Analytics endpoint with Bearer token', () async {
    final loginRes = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'email': 'hr@connect.com', 'password': 'admin123'}),
    );
    final token = jsonDecode(loginRes.body)['token'];

    final analyticsRes = await http.get(
      Uri.parse('$baseUrl/hr/analytics'),
      headers: {'Authorization': 'Bearer $token'},
    );

    expect(analyticsRes.statusCode, equals(200));
    final data = jsonDecode(analyticsRes.body);
    expect(data['totalEmployees'], isA<int>());
  });
}
