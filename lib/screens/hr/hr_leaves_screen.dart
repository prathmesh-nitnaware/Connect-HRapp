import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/hr_provider.dart';
import '../../widgets/status_badge.dart';

class HRLeavesScreen extends StatefulWidget {
  const HRLeavesScreen({super.key});

  @override
  State<HRLeavesScreen> createState() => _HRLeavesScreenState();
}

class _HRLeavesScreenState extends State<HRLeavesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HRProvider>().fetchLeaves();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hrProvider = context.watch<HRProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Approve Leaves', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: hrProvider.isLoadingLeaves
          ? const Center(child: CircularProgressIndicator())
          : hrProvider.statusMessage != null && hrProvider.leaves.isEmpty
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
                          onPressed: () => hrProvider.fetchLeaves(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : hrProvider.leaves.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy_outlined, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No leave requests found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => hrProvider.fetchLeaves(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: hrProvider.leaves.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final leave = hrProvider.leaves[index];
                          final isPending = leave.status.toLowerCase() == 'pending';

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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        leave.employeeName,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      StatusBadge(label: leave.status),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${leave.leaveType} • ${leave.date}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    leave.reason,
                                    style: theme.textTheme.bodyMedium,
                                  ),

                                  if (isPending) ...[
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              hrProvider.updateLeaveStatus(
                                                leaveId: leave.id,
                                                status: 'Approved',
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.success,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            child: const Text('Approve'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              hrProvider.updateLeaveStatus(
                                                leaveId: leave.id,
                                                status: 'Rejected',
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.errorRed,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            child: const Text('Reject'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
