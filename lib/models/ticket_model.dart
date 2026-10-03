class TicketMessage {
  final String senderId;
  final String senderName;
  final String senderRole;
  final String message;
  final String timestamp;

  TicketMessage({
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.timestamp,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      senderId: json['sender_id']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? '',
      senderRole: json['sender_role']?.toString() ?? 'EMPLOYEE',
      message: json['message']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'sender_id': senderId,
        'sender_name': senderName,
        'sender_role': senderRole,
        'message': message,
        'timestamp': timestamp,
      };
}

class HelpdeskTicket {
  final String id;
  final String employeeId;
  final String employeeName;
  final String subject;
  final String category;
  final String priority;
  final String status;
  final String createdAt;
  final String updatedAt;
  final List<TicketMessage> messages;

  HelpdeskTicket({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.subject,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  factory HelpdeskTicket.fromJson(Map<String, dynamic> json) {
    return HelpdeskTicket(
      id: json['id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      priority: json['priority']?.toString() ?? 'Medium',
      status: json['status']?.toString() ?? 'Open',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => TicketMessage.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
