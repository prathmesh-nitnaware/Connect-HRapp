class HRAnalyticsResponse {
  final int totalEmployees;
  final int pendingLeaves;
  final int todayAttendance;

  HRAnalyticsResponse({
    required this.totalEmployees,
    required this.pendingLeaves,
    required this.todayAttendance,
  });

  factory HRAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    return HRAnalyticsResponse(
      totalEmployees: (json['totalEmployees'] as num?)?.toInt() ?? 0,
      pendingLeaves: (json['pendingLeaves'] as num?)?.toInt() ?? 0,
      todayAttendance: (json['todayAttendance'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalEmployees': totalEmployees,
        'pendingLeaves': pendingLeaves,
        'todayAttendance': todayAttendance,
      };
}
