import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hr_provider.dart';
import '../../widgets/status_badge.dart';

class HRAttendanceScreen extends StatefulWidget {
  const HRAttendanceScreen({super.key});

  @override
  State<HRAttendanceScreen> createState() => _HRAttendanceScreenState();
}

class _HRAttendanceScreenState extends State<HRAttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HRProvider>().fetchAttendance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hrProvider = context.watch<HRProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Attendance', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: hrProvider.isLoadingAttendance
          ? const Center(child: CircularProgressIndicator())
          : hrProvider.statusMessage != null && hrProvider.attendanceRecords.isEmpty
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
                          onPressed: () => hrProvider.fetchAttendance(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : hrProvider.attendanceRecords.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_note_outlined, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No attendance records found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => hrProvider.fetchAttendance(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: hrProvider.attendanceRecords.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final record = hrProvider.attendanceRecords[index];

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
                                        record.employeeName,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        record.date,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      StatusBadge(
                                        label: 'In: ${record.punchIn.isNotEmpty ? record.punchIn : "--:--:--"}',
                                        backgroundColor: colorScheme.primaryContainer,
                                        textColor: colorScheme.onPrimaryContainer,
                                      ),
                                      StatusBadge(
                                        label: 'Out: ${record.punchOut.isNotEmpty ? record.punchOut : "--:--:--"}',
                                        backgroundColor: colorScheme.secondaryContainer,
                                        textColor: colorScheme.onSecondaryContainer,
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
