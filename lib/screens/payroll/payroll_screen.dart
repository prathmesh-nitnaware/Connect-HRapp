import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/session_service.dart';
import '../../core/utils/pdf_generator.dart';
import '../../models/payroll_model.dart';
import '../../providers/employee_provider.dart';
import '../../providers/hr_provider.dart';
import '../../providers/payroll_provider.dart';
import '../../widgets/status_badge.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final session = context.read<SessionService>();
    final provider = context.read<PayrollProvider>();
    if (session.isHR) {
      provider.fetchAllPayslips(token: session.token);
      context.read<HRProvider>().fetchEmployees();
    } else {
      provider.fetchMyPayslips(token: session.token);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();
    final payrollProvider = context.watch<PayrollProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Payroll & Compensation', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 3,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              icon: const Icon(Icons.receipt_long_outlined),
              text: session.isHR ? 'All Payslips' : 'My Payslips',
            ),
            const Tab(
              icon: Icon(Icons.account_balance_wallet_outlined),
              text: 'Salary Structure',
            ),
          ],
        ),
        actions: [
          if (session.isHR)
            IconButton.filledTonal(
              icon: const Icon(Icons.add),
              tooltip: 'Generate Payslip',
              onPressed: () => _showGeneratePayslipDialog(context),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: payrollProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPayslipsList(payrollProvider.payslips, theme),
                _buildSalaryStructureView(payrollProvider.salaryStructure, theme),
              ],
            ),
    );
  }

  Widget _buildPayslipsList(List<Payslip> payslips, ThemeData theme) {
    if (payslips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_outlined, size: 56, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text('No Payslips Available', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Generated monthly digital payslips will appear here.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: payslips.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final slip = payslips[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showPayslipDetailsModal(context, slip),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.payments_outlined, color: theme.colorScheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(slip.month, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(slip.employeeName, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                      StatusBadge(
                        label: slip.status.toUpperCase(),
                        backgroundColor: AppColors.successContainer,
                        textColor: AppColors.onSuccessContainer,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Net Disbursed', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('₹ ${slip.netPay.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text('Export PDF'),
                        onPressed: () async {
                          await PdfGenerator.generateAndPrintPayslip(slip);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSalaryStructureView(SalaryStructure? structure, ThemeData theme) {
    if (structure == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.tertiary ?? Colors.indigo.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Annual Compensation (CTC)', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Tier-1 Structure', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '₹ ${structure.baseAnnualCtc.toStringAsFixed(0)} / annum',
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Monthly Gross', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text('₹ ${structure.monthlyGross.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(height: 28, width: 1, color: Colors.white24),
                      Column(
                        children: [
                          const Text('Estimated In-Hand', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text('₹ ${structure.netTakeHome.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Monthly Earnings Breakdown', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildBreakdownTile('Basic Salary (50%)', '₹ ${structure.basic.toStringAsFixed(0)}', Icons.account_balance_outlined, Colors.blue),
          _buildBreakdownTile('House Rent Allowance (HRA)', '₹ ${structure.hra.toStringAsFixed(0)}', Icons.home_outlined, Colors.teal),
          _buildBreakdownTile('Special & Flexible Allowances', '₹ ${structure.specialAllowance.toStringAsFixed(0)}', Icons.card_giftcard_outlined, Colors.indigo),
          const SizedBox(height: 20),
          Text('Mandatory Deductions & Taxes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildBreakdownTile('Provident Fund (PF)', '- ₹ ${structure.pf.toStringAsFixed(0)}', Icons.savings_outlined, Colors.orange),
          _buildBreakdownTile('Estimated TDS / Income Tax', '- ₹ ${structure.tdsEstimated.toStringAsFixed(0)}', Icons.receipt_long_outlined, Colors.red),
        ],
      ),
    );
  }

  Widget _buildBreakdownTile(String title, String amount, IconData icon, Color color) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  void _showPayslipDetailsModal(BuildContext context, Payslip slip) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Payslip Details', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Employee Name', slip.employeeName),
            _buildDetailRow('Pay Period', slip.month),
            _buildDetailRow('Basic Salary', '₹ ${slip.basicSalary.toStringAsFixed(0)}'),
            _buildDetailRow('HRA', '₹ ${slip.hra.toStringAsFixed(0)}'),
            _buildDetailRow('Allowances', '₹ ${slip.allowances.toStringAsFixed(0)}'),
            _buildDetailRow('Provident Fund', '- ₹ ${slip.providentFund.toStringAsFixed(0)}', isDeduction: true),
            _buildDetailRow('Tax (TDS)', '- ₹ ${slip.taxDeductions.toStringAsFixed(0)}', isDeduction: true),
            const Divider(height: 24),
            _buildDetailRow('Net Payable', '₹ ${slip.netPay.toStringAsFixed(0)}', isTotal: true),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Export Official PDF Slip', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.pop(ctx);
                await PdfGenerator.generateAndPrintPayslip(slip);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isDeduction = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isDeduction ? Colors.red.shade700 : null)),
          Text(value, style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.w600, color: isDeduction ? Colors.red.shade700 : (isTotal ? AppColors.primary600 : null))),
        ],
      ),
    );
  }

  void _showGeneratePayslipDialog(BuildContext context) {
    final hrProvider = context.read<HRProvider>();
    final employees = hrProvider.employees;

    String? selectedEmpId = employees.isNotEmpty ? employees.first.id : null;
    String selectedEmpName = employees.isNotEmpty ? employees.first.name : 'Prathmesh Nitnaware';

    final monthController = TextEditingController(text: 'October 2026');
    final basicController = TextEditingController(text: '50000');
    final hraController = TextEditingController(text: '20000');
    final allowancesController = TextEditingController(text: '10000');
    final pfController = TextEditingController(text: '3500');
    final taxController = TextEditingController(text: '4500');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final basic = double.tryParse(basicController.text) ?? 0;
          final hra = double.tryParse(hraController.text) ?? 0;
          final allow = double.tryParse(allowancesController.text) ?? 0;
          final pf = double.tryParse(pfController.text) ?? 0;
          final tax = double.tryParse(taxController.text) ?? 0;
          final net = (basic + hra + allow) - (pf + tax);

          return AlertDialog(
            title: const Text('Generate Employee Payslip', style: TextStyle(fontWeight: FontWeight.bold)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (employees.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: selectedEmpId ?? employees.first.id,
                      decoration: const InputDecoration(labelText: 'Select Employee', border: OutlineInputBorder()),
                      items: employees.map((e) => DropdownMenuItem(value: e.id, child: Text('${e.name} (${e.department})'))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final match = employees.firstWhere((e) => e.id == val);
                          setDialogState(() {
                            selectedEmpId = val;
                            selectedEmpName = match.name;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(controller: monthController, decoration: const InputDecoration(labelText: 'Pay Period', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: basicController,
                          decoration: const InputDecoration(labelText: 'Basic (₹)', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: hraController,
                          decoration: const InputDecoration(labelText: 'HRA (₹)', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: allowancesController,
                    decoration: const InputDecoration(labelText: 'Allowances (₹)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: pfController,
                          decoration: const InputDecoration(labelText: 'PF (₹)', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: taxController,
                          decoration: const InputDecoration(labelText: 'Tax/TDS (₹)', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Calculated Net Pay:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary800)),
                        Text('₹ ${net.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary800)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final session = context.read<SessionService>();
                  final targetId = selectedEmpId ?? 'emp_001';

                  final success = await context.read<PayrollProvider>().generatePayslip({
                    'employee_id': targetId,
                    'employee_name': selectedEmpName,
                    'month': monthController.text.trim(),
                    'basic_salary': double.tryParse(basicController.text) ?? 0,
                    'hra': double.tryParse(hraController.text) ?? 0,
                    'allowances': double.tryParse(allowancesController.text) ?? 0,
                    'deductions': double.tryParse(pfController.text) ?? 0,
                    'tax': double.tryParse(taxController.text) ?? 0,
                  }, token: session.token);

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Payslip generated & issued to employee! 💰' : 'Failed to generate payslip'),
                        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text('Issue Payslip'),
              ),
            ],
          );
        },
      ),
    );
  }
}
