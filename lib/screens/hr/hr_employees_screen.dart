import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/employee_model.dart';
import '../../providers/hr_provider.dart';
import '../../widgets/dialogs/hire_employee_dialog.dart';
import '../../widgets/status_badge.dart';

class HREmployeesScreen extends StatefulWidget {
  const HREmployeesScreen({super.key});

  @override
  State<HREmployeesScreen> createState() => _HREmployeesScreenState();
}

class _HREmployeesScreenState extends State<HREmployeesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HRProvider>().fetchEmployees();
    });
  }

  final List<String> _departments = [
    'Engineering',
    'IT',
    'HR',
    'Sales',
    'Marketing',
    'Design',
    'Operations',
    'Unassigned',
  ];

  Future<void> _confirmDelete(HREmployee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Confirm Offboarding'),
        content: Text('Are you sure you want to remove ${employee.name} from the company?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<HRProvider>().deleteEmployee(employee.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hrProvider = context.watch<HRProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Employees', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final hired = await HireEmployeeDialog.show(context);
          if (hired == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('New employee hired successfully!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: const Icon(Icons.add, size: 28),
      ),
      body: hrProvider.isLoadingEmployees
          ? const Center(child: CircularProgressIndicator())
          : hrProvider.statusMessage != null && hrProvider.employees.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                        const SizedBox(height: 12),
                        Text(
                          hrProvider.statusMessage!,
                          style: TextStyle(color: colorScheme.error, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => hrProvider.fetchEmployees(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : hrProvider.employees.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No employees found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the + button to hire your first employee.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => hrProvider.fetchEmployees(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: hrProvider.employees.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final employee = hrProvider.employees[index];
                          return Card(
                            color: colorScheme.surfaceContainerHighest,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Circle Avatar with first initial
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: colorScheme.onPrimary,
                                        child: Text(
                                          employee.name.isNotEmpty
                                              ? employee.name.substring(0, 1).toUpperCase()
                                              : 'E',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              employee.name,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              employee.email,
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      StatusBadge(label: employee.department),

                                      Row(
                                        children: [
                                          PopupMenuButton<String>(
                                            tooltip: 'Change Department',
                                            child: TextButton(
                                              onPressed: null,
                                              child: Text(
                                                'Change Dept',
                                                style: TextStyle(
                                                  color: colorScheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            onSelected: (String newDept) {
                                              hrProvider.updateEmployeeDepartment(
                                                employeeId: employee.id,
                                                newDepartment: newDept,
                                              );
                                            },
                                            itemBuilder: (BuildContext context) {
                                              return _departments.map((String dept) {
                                                return PopupMenuItem<String>(
                                                  value: dept,
                                                  child: Text(dept),
                                                );
                                              }).toList();
                                            },
                                          ),

                                          TextButton(
                                            onPressed: () => _confirmDelete(employee),
                                            style: TextButton.styleFrom(
                                              foregroundColor: AppColors.errorRed,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
