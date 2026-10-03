import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/attendance_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/dialogs/apply_leave_dialog.dart';
import '../../widgets/dialogs/server_config_dialog.dart';
import '../../widgets/status_badge.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  void _refreshAllData() {
    final empProvider = context.read<EmployeeProvider>();
    empProvider.fetchProfile();
    empProvider.fetchAttendanceHistory();
    empProvider.fetchLeaveHistory();
    context.read<NotificationProvider>().fetchNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.landing,
        (route) => false,
      );
    }
  }

  AttendanceHistory? _getTodayAttendance(List<AttendanceHistory> history) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    for (final r in history) {
      if (r.date == todayStr) return r;
    }
    return history.isNotEmpty ? history.first : null;
  }

  Future<void> _handlePunchIn() async {
    final empProvider = context.read<EmployeeProvider>();
    final success = await empProvider.punchIn();
    if (mounted) {
      final msg = empProvider.statusMessage ?? (success ? 'Punched in successfully! 🎉' : 'Failed to punch in');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _handlePunchOut() async {
    final empProvider = context.read<EmployeeProvider>();
    final success = await empProvider.punchOut();
    if (mounted) {
      final msg = empProvider.statusMessage ?? (success ? 'Punched out successfully! See you tomorrow 👋' : 'Failed to punch out');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: success ? Colors.orange.shade800 : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final empProvider = context.watch<EmployeeProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final notifProvider = context.watch<NotificationProvider>();

    final todayAttendance = _getTodayAttendance(empProvider.attendanceHistory);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isTodayRecord = todayAttendance?.date == todayStr;
    final hasPunchedInToday = isTodayRecord && (todayAttendance?.punchIn.isNotEmpty == true);
    final hasPunchedOutToday = isTodayRecord && (todayAttendance?.punchOut.isNotEmpty == true);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.work_outline, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Connect HR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
          ],
        ),
        actions: [
          // Notification Bell with Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
              ),
              if (notifProvider.unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${notifProvider.unreadCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Server Settings',
            onPressed: () => ServerConfigDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Header Card
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.tertiary ?? Colors.indigo.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                empProvider.profile?.name.isNotEmpty == true
                                    ? 'Welcome, ${empProvider.profile!.name}!'
                                    : 'Welcome Back!',
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        if (empProvider.profile?.department.isNotEmpty == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white30),
                            ),
                            child: Text(
                              empProvider.profile!.department,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Smart Punch Widget Card
              _buildSmartPunchCard(
                context,
                hasPunchedInToday: hasPunchedInToday,
                hasPunchedOutToday: hasPunchedOutToday,
                todayRecord: isTodayRecord ? todayAttendance : null,
                isLoading: empProvider.isActionLoading,
              ),

              const SizedBox(height: 22),

              // Enterprise Workplace Hub
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Workplace Modules',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () => ApplyLeaveDialog.show(context),
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('Apply Leave'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.35,
                children: [
                  _buildHubCard(
                    title: 'Smart Attendance',
                    subtitle: 'GPS & QR Check-in',
                    icon: Icons.location_on,
                    color: Colors.teal,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.smartAttendance),
                  ),
                  _buildHubCard(
                    title: 'Payroll & Slips',
                    subtitle: 'PDF Payslips & CTC',
                    icon: Icons.account_balance_wallet,
                    color: Colors.indigo,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.payroll),
                  ),
                  _buildHubCard(
                    title: 'Announcements',
                    subtitle: 'Company Notices',
                    icon: Icons.campaign,
                    color: Colors.orange.shade800,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.announcements),
                  ),
                  _buildHubCard(
                    title: 'Expense Claims',
                    subtitle: 'Receipts & Refunds',
                    icon: Icons.receipt_long,
                    color: Colors.purple,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.expenses),
                  ),
                  _buildHubCard(
                    title: 'HR Helpdesk',
                    subtitle: 'Live Tickets & Chat',
                    icon: Icons.support_agent,
                    color: Colors.blue,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.helpdesk),
                  ),
                  _buildHubCard(
                    title: 'Vault & Assets',
                    subtitle: 'Docs & IT Hardware',
                    icon: Icons.folder_shared,
                    color: Colors.amber.shade900,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.documentVault),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Activity History Section
              Text(
                'Recent Activity',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              TabBar(
                controller: _tabController,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                indicatorColor: colorScheme.primary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Attendance Log'),
                  Tab(text: 'Leave Requests'),
                ],
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 260,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    empProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : empProvider.attendanceHistory.isEmpty
                            ? const Center(child: Text('No attendance records yet.'))
                            : ListView.separated(
                                itemCount: empProvider.attendanceHistory.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final record = empProvider.attendanceHistory[index];
                                  return Card(
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(record.date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                              Text(record.method.toUpperCase(), style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              StatusBadge(
                                                label: 'In: ${record.punchIn.isNotEmpty ? record.punchIn : "--"}',
                                                backgroundColor: AppColors.successContainer,
                                                textColor: AppColors.onSuccessContainer,
                                              ),
                                              const SizedBox(width: 6),
                                              StatusBadge(
                                                label: 'Out: ${record.punchOut.isNotEmpty ? record.punchOut : "--"}',
                                                backgroundColor: AppColors.warningContainer,
                                                textColor: AppColors.onWarningContainer,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                    empProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : empProvider.leaveHistory.isEmpty
                            ? const Center(child: Text('No leave requests submitted.'))
                            : ListView.separated(
                                itemCount: empProvider.leaveHistory.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final leave = empProvider.leaveHistory[index];
                                  return Card(
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${leave.startDate} to ${leave.endDate}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                              Text(leave.reason, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                                            ],
                                          ),
                                          StatusBadge(
                                            label: leave.status.toUpperCase(),
                                            backgroundColor: leave.status.toLowerCase() == 'approved'
                                                ? AppColors.successContainer
                                                : leave.status.toLowerCase() == 'rejected'
                                                    ? AppColors.errorContainer
                                                    : AppColors.warningContainer,
                                            textColor: leave.status.toLowerCase() == 'approved'
                                                ? AppColors.onSuccessContainer
                                                : leave.status.toLowerCase() == 'rejected'
                                                    ? AppColors.onErrorContainer
                                                    : AppColors.onWarningContainer,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartPunchCard(
    BuildContext context, {
    required bool hasPunchedInToday,
    required bool hasPunchedOutToday,
    required AttendanceHistory? todayRecord,
    required bool isLoading,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (hasPunchedOutToday) {
      // Completed for the day
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.green.shade200),
            color: Colors.green.withValues(alpha: 0.05),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: Colors.green.shade800, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Workday Completed ✅', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('In: ${todayRecord?.punchIn} • Out: ${todayRecord?.punchOut}', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.smartAttendance),
                icon: const Icon(Icons.insights, size: 16),
                label: const Text('View Stats'),
              ),
            ],
          ),
        ),
      );
    }

    if (hasPunchedInToday) {
      // Currently punched in - on duty
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.amber.shade400, width: 1.5),
            color: Colors.amber.withValues(alpha: 0.06),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Active Shift (On Duty)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('Started at ${todayRecord?.punchIn}', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    tooltip: 'Geofence / QR',
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.smartAttendance),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.logout),
                  label: Text(isLoading ? 'Recording Punch Out...' : 'Punch Out for the Day', style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: isLoading ? null : _handlePunchOut,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Not punched in yet
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.access_time_filled, color: colorScheme.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Daily Check-In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Record your arrival to begin shift', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.login),
                    label: Text(isLoading ? 'Punching In...' : 'Quick Punch In', style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: isLoading ? null : _handlePunchIn,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('QR / GPS'),
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.smartAttendance),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHubCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade400),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
