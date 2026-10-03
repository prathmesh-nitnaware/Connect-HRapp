class ExpenseClaim {
  final String id;
  final String employeeId;
  final String employeeName;
  final String title;
  final String category;
  final double amount;
  final String date;
  final String? receiptUrl;
  final String status;
  final String reviewerComment;
  final String createdAt;

  ExpenseClaim({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.receiptUrl,
    required this.status,
    required this.reviewerComment,
    required this.createdAt,
  });

  factory ExpenseClaim.fromJson(Map<String, dynamic> json) {
    return ExpenseClaim(
      id: json['id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date']?.toString() ?? '',
      receiptUrl: json['receipt_url']?.toString(),
      status: json['status']?.toString() ?? 'Pending',
      reviewerComment: json['reviewer_comment']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employee_id': employeeId,
        'employee_name': employeeName,
        'title': title,
        'category': category,
        'amount': amount,
        'date': date,
        'receipt_url': receiptUrl,
        'status': status,
        'reviewer_comment': reviewerComment,
        'created_at': createdAt,
      };
}
