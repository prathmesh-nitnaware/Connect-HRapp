import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/session_service.dart';
import '../../models/ticket_model.dart';
import '../../providers/ticket_provider.dart';
import 'ticket_chat_screen.dart';

class HelpdeskScreen extends StatefulWidget {
  const HelpdeskScreen({super.key});

  @override
  State<HelpdeskScreen> createState() => _HelpdeskScreenState();
}

class _HelpdeskScreenState extends State<HelpdeskScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final session = context.read<SessionService>();
    final provider = context.read<TicketProvider>();
    if (session.isHR) {
      provider.fetchAllTickets(token: session.token);
    } else {
      provider.fetchMyTickets(token: session.token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();
    final provider = context.watch<TicketProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(session.isHR ? 'HR Helpdesk & Inquiries' : 'HR Helpdesk & Support'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.tickets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.support_agent, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      const SizedBox(height: 16),
                      Text('No tickets found', style: theme.textTheme.titleMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = provider.tickets[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: _getPriorityColor(ticket.priority).withOpacity(0.15),
                          child: Icon(Icons.chat_bubble_outline, color: _getPriorityColor(ticket.priority)),
                        ),
                        title: Text(ticket.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('${ticket.category} • Priority: ${ticket.priority}'),
                            const SizedBox(height: 2),
                            Text('Employee: ${ticket.employeeName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildStatusBadge(ticket.status),
                            const SizedBox(height: 4),
                            Text('${ticket.messages.length} msg', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TicketChatScreen(ticket: ticket),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_comment),
        label: const Text('Raise Ticket'),
        onPressed: () => _showCreateTicketDialog(context),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.deepOrange;
      case 'medium':
        return Colors.amber.shade800;
      case 'low':
      default:
        return Colors.blue;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status.toLowerCase() == 'resolved') color = Colors.green;
    if (status.toLowerCase() == 'closed') color = Colors.grey;
    if (status.toLowerCase() == 'in progress') color = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showCreateTicketDialog(BuildContext context) {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    String category = 'Payroll';
    String priority = 'Medium';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Raise Helpdesk Ticket'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Ticket Subject', hintText: 'e.g. Discrepancy in HRA allowance'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ['Payroll', 'IT Support', 'Workplace', 'General'].map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => category = val);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: ['Low', 'Medium', 'High', 'Urgent'].map((p) {
                    return DropdownMenuItem(value: p, child: Text(p));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => priority = val);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Detailed Message', hintText: 'Describe your issue in detail...'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (subjectController.text.trim().isEmpty || messageController.text.trim().isEmpty) return;
                final session = context.read<SessionService>();
                final success = await context.read<TicketProvider>().createTicket({
                  'subject': subjectController.text.trim(),
                  'category': category,
                  'priority': priority,
                  'message': messageController.text.trim(),
                }, token: session.token);

                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Ticket created successfully!' : 'Failed to create ticket')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
