import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/session_service.dart';
import '../../models/ticket_model.dart';
import '../../providers/ticket_provider.dart';

class TicketChatScreen extends StatefulWidget {
  final HelpdeskTicket ticket;

  const TicketChatScreen({super.key, required this.ticket});

  @override
  State<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<TicketChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final session = context.read<SessionService>();
    final user = session.currentUser;
    final senderId = user?.id ?? 'EMP001';
    final senderName = user?.name ?? (session.isHR ? 'HR Admin' : 'Employee');
    final role = session.isHR ? 'HR' : 'EMPLOYEE';

    context.read<TicketProvider>().sendMessage(
          widget.ticket.id,
          text,
          senderId,
          senderName,
          role,
          token: session.token,
        );

    _msgController.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();
    final provider = context.watch<TicketProvider>();
    final currentTicket = provider.tickets.firstWhere(
      (t) => t.id == widget.ticket.id,
      orElse: () => widget.ticket,
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currentTicket.subject, style: const TextStyle(fontSize: 16)),
            Text('${currentTicket.category} • ${currentTicket.status}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          if (session.isHR)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (newStatus) {
                provider.updateStatus(currentTicket.id, newStatus, token: session.token);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'Open', child: Text('Mark Open')),
                const PopupMenuItem(value: 'In Progress', child: Text('Mark In Progress')),
                const PopupMenuItem(value: 'Resolved', child: Text('Mark Resolved')),
                const PopupMenuItem(value: 'Closed', child: Text('Mark Closed')),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Header info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Created by: ${currentTicket.employeeName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                _buildStatusChip(currentTicket.status),
              ],
            ),
          ),

          // Message Bubbles
          Expanded(
            child: currentTicket.messages.isEmpty
                ? const Center(child: Text('No messages yet in this ticket.'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: currentTicket.messages.length,
                    itemBuilder: (context, index) {
                      final msg = currentTicket.messages[index];
                      final isMe = (session.isHR && msg.senderRole == 'HR') ||
                          (!session.isHR && msg.senderRole != 'HR');

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                          decoration: BoxDecoration(
                            color: isMe ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 0),
                              bottomRight: Radius.circular(isMe ? 0 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.senderName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isMe ? Colors.white70 : theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                msg.message,
                                style: TextStyle(
                                  color: isMe ? Colors.white : theme.colorScheme.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                msg.timestamp.contains('T') ? msg.timestamp.split('T').last.substring(0, 5) : msg.timestamp,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe ? Colors.white60 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Chat Input Bar
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.orange;
    if (status.toLowerCase() == 'resolved') color = Colors.green;
    if (status.toLowerCase() == 'closed') color = Colors.grey;
    if (status.toLowerCase() == 'in progress') color = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
