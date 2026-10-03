class DepartmentHeadcount {
  final String department;
  final int count;

  DepartmentHeadcount({required this.department, required this.count});

  factory DepartmentHeadcount.fromJson(Map<String, dynamic> json) {
    return DepartmentHeadcount(
      department: json['department']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class AttendanceTrendDay {
  final String day;
  final double presentRate;

  AttendanceTrendDay({required this.day, required this.presentRate});

  factory AttendanceTrendDay.fromJson(Map<String, dynamic> json) {
    return AttendanceTrendDay(
      day: json['day']?.toString() ?? '',
      presentRate: (json['present_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ExpenseCategoryTotal {
  final String category;
  final double total;

  ExpenseCategoryTotal({required this.category, required this.total});

  factory ExpenseCategoryTotal.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryTotal(
      category: json['category']?.toString() ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AdvancedHRAnalytics {
  final double turnoverRate;
  final int activeHeadcount;
  final double avgMonthlyWorkHours;
  final List<DepartmentHeadcount> departmentHeadcounts;
  final List<AttendanceTrendDay> attendanceTrends;
  final List<ExpenseCategoryTotal> expenseBreakdown;

  AdvancedHRAnalytics({
    required this.turnoverRate,
    required this.activeHeadcount,
    required this.avgMonthlyWorkHours,
    required this.departmentHeadcounts,
    required this.attendanceTrends,
    required this.expenseBreakdown,
  });

  factory AdvancedHRAnalytics.fromJson(Map<String, dynamic> json) {
    return AdvancedHRAnalytics(
      turnoverRate: (json['turnover_rate'] as num?)?.toDouble() ?? 0.0,
      activeHeadcount: (json['active_headcount'] as num?)?.toInt() ?? 0,
      avgMonthlyWorkHours: (json['avg_monthly_work_hours'] as num?)?.toDouble() ?? 0.0,
      departmentHeadcounts: (json['department_headcounts'] as List<dynamic>?)
              ?.map((d) => DepartmentHeadcount.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      attendanceTrends: (json['attendance_trend_weekly'] as List<dynamic>?)
              ?.map((a) => AttendanceTrendDay.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      expenseBreakdown: (json['expense_breakdown'] as List<dynamic>?)
              ?.map((e) => ExpenseCategoryTotal.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
