import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/session_service.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = context.read<SessionService>();
      context.read<NotificationProvider>().fetchNotifications(token: session.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();
    final provider = context.watch<NotificationProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications & Reminders'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
              label: const Text('Mark all read', style: TextStyle(color: Colors.white)),
              onPressed: () => provider.markAllAsRead(token: session.token),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.fetchNotifications(token: session.token),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      const SizedBox(height: 16),
                      Text('You have no notifications', style: theme.textTheme.titleMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.notifications.length,
                  itemBuilder: (context, index) {
                    final item = provider.notifications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: item.isRead ? 1 : 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: item.isRead ? null : theme.colorScheme.primaryContainer.withOpacity(0.25),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        leading: CircleAvatar(
                          backgroundColor: _getTypeColor(item.type).withOpacity(0.15),
                          child: Icon(_getTypeIcon(item.type), color: _getTypeColor(item.type)),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold),
                              ),
                            ),
                            if (!item.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(item.message, style: const TextStyle(height: 1.3)),
                            const SizedBox(height: 6),
                            Text(
                              item.createdAt.contains('T') ? item.createdAt.split('T').first : item.createdAt,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        onTap: () {
                          if (!item.isRead) {
                            provider.markAsRead(item.id, token: session.token);
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'LEAVE':
        return Icons.event_available;
      case 'PAYROLL':
        return Icons.attach_money;
      case 'ATTENDANCE':
        return Icons.alarm;
      case 'EXPENSE':
        return Icons.receipt_long;
      default:
        return Icons.notifications;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'LEAVE':
        return Colors.blue;
      case 'PAYROLL':
        return Colors.green;
      case 'ATTENDANCE':
        return Colors.orange;
      case 'EXPENSE':
        return Colors.purple;
      default:
        return Colors.indigo;
    }
  }
}
