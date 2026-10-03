class AttendanceRequest {
  final String action; // 'punch_in' or 'punch_out'
  final String? punchType;
  final double? latitude;
  final double? longitude;
  final String? qrCode;

  AttendanceRequest({
    String? action,
    String? punchType,
    this.latitude,
    this.longitude,
    this.qrCode,
  })  : action = action ?? (punchType?.toLowerCase() == 'out' ? 'punch_out' : 'punch_in'),
        punchType = punchType ?? action;

  Map<String, dynamic> toJson() => {
        'action': action,
        'punch_type': punchType,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (qrCode != null) 'qr_code': qrCode,
      };
}

class AttendanceResponse {
  final String message;

  AttendanceResponse({required this.message});

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceResponse(
      message: json['message'] as String? ?? 'Attendance recorded successfully',
    );
  }
}

class AttendanceHistory {
  final String date;
  final String punchIn;
  final String punchOut;
  final String method;

  AttendanceHistory({
    required this.date,
    required this.punchIn,
    required this.punchOut,
    this.method = 'Standard',
  });

  factory AttendanceHistory.fromJson(Map<String, dynamic> json) {
    return AttendanceHistory(
      date: json['date'] as String? ?? '',
      punchIn: json['punch_in'] as String? ?? '',
      punchOut: json['punch_out'] as String? ?? '',
      method: json['method'] as String? ?? 'Standard',
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'punch_in': punchIn,
        'punch_out': punchOut,
        'method': method,
      };
}

class HRAttendanceRecord {
  final String id;
  final String employeeName;
  final String date;
  final String punchIn;
  final String punchOut;

  HRAttendanceRecord({
    required this.id,
    required this.employeeName,
    required this.date,
    required this.punchIn,
    required this.punchOut,
  });

  factory HRAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return HRAttendanceRecord(
      id: json['id'] as String? ?? '',
      employeeName: json['employee_name'] as String? ?? 'Unknown',
      date: json['date'] as String? ?? '',
      punchIn: json['punch_in'] as String? ?? '',
      punchOut: json['punch_out'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employee_name': employeeName,
        'date': date,
        'punch_in': punchIn,
        'punch_out': punchOut,
      };
}
