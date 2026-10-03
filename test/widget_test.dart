import 'package:connect_hr/core/services/session_service.dart';
import 'package:connect_hr/main.dart';
import 'package:connect_hr/providers/auth_provider.dart';
import 'package:connect_hr/providers/employee_provider.dart';
import 'package:connect_hr/providers/hr_provider.dart';
import 'package:connect_hr/providers/theme_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Connect HR landing screen smoke test', (WidgetTester tester) async {
    final sessionService = SessionService();
    final themeProvider = ThemeProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: sessionService),
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => EmployeeProvider()),
          ChangeNotifierProvider(create: (_) => HRProvider()),
        ],
        child: const ConnectHRApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Landing screen elements
    expect(find.text('Connect HR'), findsOneWidget);
    expect(find.text('Employee Login'), findsOneWidget);
    expect(find.text('HR Portal'), findsOneWidget);
  });
}
