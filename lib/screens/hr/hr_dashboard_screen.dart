import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hr_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/dialogs/server_config_dialog.dart';

class HRDashboardScreen extends StatefulWidget {
  const HRDashboardScreen({super.key});

  @override
  State<HRDashboardScreen> createState() => _HRDashboardScreenState();
}

class _HRDashboardScreenState extends State<HRDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    context.read<HRProvider>().fetchAnalytics();
    context.read<HRProvider>().fetchEmployees();
    context.read<NotificationProvider>().fetchNotifications();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hrProvider = context.watch<HRProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final analytics = hrProvider.analytics;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.teal.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.admin_panel_settings, color: Colors.teal.shade800, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('HR Command Center', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
          ],
        ),
        actions: [
          // Notification Bell with Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Alerts & Notices',
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
        onRefresh: () async => _refreshData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Executive Banner Card
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade800, Colors.teal.shade600, Colors.indigo.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.shade800.withValues(alpha: 0.35),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Executive Overview',
                              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Enterprise Workforce',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            DateFormat('MMMM yyyy').format(DateTime.now()),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // KPI Metric Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Staff',
                      value: hrProvider.isLoadingAnalytics ? '...' : '${analytics?.totalEmployees ?? 0}',
                      icon: Icons.groups,
                      gradientColors: [Colors.blue.shade600, Colors.blue.shade800],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Active Today',
                      value: hrProvider.isLoadingAnalytics ? '...' : '${analytics?.todayAttendance ?? 0}',
                      icon: Icons.how_to_reg,
                      gradientColors: [Colors.green.shade600, Colors.green.shade800],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Pending Leaves',
                      value: hrProvider.isLoadingAnalytics ? '...' : '${analytics?.pendingLeaves ?? 0}',
                      icon: Icons.pending_actions,
                      gradientColors: [Colors.orange.shade700, Colors.orange.shade900],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Category 1: Financial & Compensation
              _buildCategoryHeader('Financial & Compensation'),
              const SizedBox(height: 10),
              _buildModernActionTile(
                title: 'Payroll & Digital Payslips',
                subtitle: 'Issue monthly slips, configure CTC structure, export PDF records',
                icon: Icons.account_balance_wallet,
                color: Colors.indigo,
                onTap: () => Navigator.pushNamed(context, AppRoutes.payroll),
              ),
              const SizedBox(height: 8),
              _buildModernActionTile(
                title: 'Expense Claims & Approvals',
                subtitle: 'Review receipts, approve reimbursements, manage payout status',
                icon: Icons.receipt_long,
                color: Colors.purple,
                onTap: () => Navigator.pushNamed(context, AppRoutes.expenses),
              ),

              const SizedBox(height: 20),

              // Category 2: Staff & Operations
              _buildCategoryHeader('Staff & Operations'),
              const SizedBox(height: 10),
              _buildModernActionTile(
                title: 'Reception Kiosk & Smart Attendance',
                subtitle: 'Display dynamic reception QR scanner & GPS geofence perimeter',
                icon: Icons.qr_code_scanner,
                color: Colors.teal,
                onTap: () => Navigator.pushNamed(context, AppRoutes.smartAttendance),
              ),
              const SizedBox(height: 8),
              _buildModernActionTile(
                title: 'Leave Requests & Approvals',
                subtitle: 'Review pending applications and manage team time-off schedule',
                icon: Icons.event_available,
                color: Colors.orange.shade800,
                onTap: () => Navigator.pushNamed(context, AppRoutes.hrLeaves),
              ),
              const SizedBox(height: 8),
              _buildModernActionTile(
                title: 'Employee Directory & Onboarding',
                subtitle: 'Hire staff, manage department roles, view profiles',
                icon: Icons.badge,
                color: Colors.blue.shade700,
                onTap: () => Navigator.pushNamed(context, AppRoutes.hrEmployees),
              ),

              const SizedBox(height: 20),

              // Category 3: Enterprise Assets & Governance
              _buildCategoryHeader('Governance, Assets & Analytics'),
              const SizedBox(height: 10),
              _buildModernActionTile(
                title: 'Company Notice Board',
                subtitle: 'Publish pinned announcements, policy updates, holiday notices',
                icon: Icons.campaign,
                color: Colors.deepOrange,
                onTap: () => Navigator.pushNamed(context, AppRoutes.announcements),
              ),
              const SizedBox(height: 8),
              _buildModernActionTile(
                title: 'HR Helpdesk & Live Ticketing',
                subtitle: 'Direct support inbox & resolve employee queries in real time',
                icon: Icons.support_agent,
                color: Colors.cyan.shade800,
                onTap: () => Navigator.pushNamed(context, AppRoutes.helpdesk),
              ),
              const SizedBox(height: 8),
              _buildModernActionTile(
                title: 'Document Vault & IT Asset Tracker',
                subtitle: 'Verify uploaded credentials & manage company laptops/hardware',
                icon: Icons.folder_shared,
                color: Colors.amber.shade900,
                onTap: () => Navigator.pushNamed(context, AppRoutes.documentVault),
              ),
              const SizedBox(height: 8),
              _buildModernActionTile(
                title: 'Advanced HR Analytics & CSV Reports',
                subtitle: 'Interactive charts, turnover metrics & one-tap CSV log exports',
                icon: Icons.analytics,
                color: Colors.blueGrey.shade800,
                onTap: () => Navigator.pushNamed(context, AppRoutes.analytics),
              ),

              const SizedBox(height: 28),

              // Bottom Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out of HR Admin Portal', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _logout,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
