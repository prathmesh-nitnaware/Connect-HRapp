class LeaveRequest {
  final String leaveType;
  final String reason;
  final String date;
  final String startDate;
  final String endDate;
  final String status;

  LeaveRequest({
    required this.leaveType,
    required this.reason,
    String? date,
    String? startDate,
    String? endDate,
    String? status,
  })  : date = date ?? startDate ?? '',
        startDate = startDate ?? date ?? '',
        endDate = endDate ?? date ?? startDate ?? '',
        status = status ?? 'Pending';

  Map<String, dynamic> toJson() => {
        'leave_type': leaveType,
        'reason': reason,
        'date': date,
        'start_date': startDate,
        'end_date': endDate,
        'status': status,
      };

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    final d = json['date'] as String? ?? json['start_date'] as String? ?? '';
    return LeaveRequest(
      leaveType: json['leave_type'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      date: d,
      startDate: json['start_date'] as String? ?? d,
      endDate: json['end_date'] as String? ?? json['start_date'] as String? ?? d,
      status: json['status'] as String? ?? 'Pending',
    );
  }
}

class LeaveResponse {
  final String message;

  LeaveResponse({required this.message});

  factory LeaveResponse.fromJson(Map<String, dynamic> json) {
    return LeaveResponse(
      message: json['message'] as String? ?? '',
    );
  }
}

class HRLeave {
  final String id;
  final String employeeName;
  final String leaveType;
  final String reason;
  final String date;
  final String status; // 'Pending', 'Approved', 'Rejected'

  HRLeave({
    required this.id,
    required this.employeeName,
    required this.leaveType,
    required this.reason,
    required this.date,
    required this.status,
  });

  factory HRLeave.fromJson(Map<String, dynamic> json) {
    return HRLeave(
      id: json['id'] as String? ?? '',
      employeeName: json['employee_name'] as String? ?? 'Unknown',
      leaveType: json['leave_type'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
    );
  }

  HRLeave copyWith({
    String? id,
    String? employeeName,
    String? leaveType,
    String? reason,
    String? date,
    String? status,
  }) {
    return HRLeave(
      id: id ?? this.id,
      employeeName: employeeName ?? this.employeeName,
      leaveType: leaveType ?? this.leaveType,
      reason: reason ?? this.reason,
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employee_name': employeeName,
        'leave_type': leaveType,
        'reason': reason,
        'date': date,
        'status': status,
      };
}

class HRLeaveUpdateRequest {
  final String status; // 'Approved' | 'Rejected'

  HRLeaveUpdateRequest({required this.status});

  Map<String, dynamic> toJson() => {
        'status': status,
      };
}
