class Payslip {
  final String id;
  final String employeeId;
  final String employeeName;
  final String month;
  final int year;
  final double basicSalary;
  final double hra;
  final double allowances;
  final double providentFund;
  final double taxDeductions;
  final double grossSalary;
  final double netPay;
  final String status;
  final String generatedAt;

  Payslip({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.month,
    this.year = 2026,
    required this.basicSalary,
    required this.hra,
    required this.allowances,
    required this.providentFund,
    required this.taxDeductions,
    required this.grossSalary,
    required this.netPay,
    required this.status,
    required this.generatedAt,
  });

  factory Payslip.fromJson(Map<String, dynamic> json) {
    final basic = (json['basic_salary'] as num?)?.toDouble() ?? 0.0;
    final hraVal = (json['hra'] as num?)?.toDouble() ?? 0.0;
    final allow = (json['allowances'] as num?)?.toDouble() ?? 0.0;
    final pfVal = (json['provident_fund'] as num?)?.toDouble() ??
        (json['deductions'] as num?)?.toDouble() ??
        0.0;
    final taxVal = (json['tax_deductions'] as num?)?.toDouble() ??
        (json['tax'] as num?)?.toDouble() ??
        0.0;
    final gross = (json['gross_salary'] as num?)?.toDouble() ??
        (basic + hraVal + allow);
    final net = (json['net_pay'] as num?)?.toDouble() ??
        (json['net_salary'] as num?)?.toDouble() ??
        (gross - pfVal - taxVal);

    return Payslip(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? 'Employee',
      month: json['month']?.toString() ?? 'Current Month',
      year: int.tryParse(json['year']?.toString() ?? '') ?? 2026,
      basicSalary: basic,
      hra: hraVal,
      allowances: allow,
      providentFund: pfVal,
      taxDeductions: taxVal,
      grossSalary: gross,
      netPay: net,
      status: json['status']?.toString() ??
          json['payment_status']?.toString() ??
          'Paid',
      generatedAt: json['generated_at']?.toString() ??
          json['generated_date']?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employee_id': employeeId,
        'employee_name': employeeName,
        'month': month,
        'year': year,
        'basic_salary': basicSalary,
        'hra': hra,
        'allowances': allowances,
        'provident_fund': providentFund,
        'tax_deductions': taxDeductions,
        'gross_salary': grossSalary,
        'net_pay': netPay,
        'status': status,
        'generated_at': generatedAt,
      };
}

class SalaryStructure {
  final String employeeId;
  final double baseAnnualCtc;
  final double monthlyGross;
  final double basic;
  final double hra;
  final double specialAllowance;
  final double pf;
  final double tdsEstimated;
  final double netTakeHome;

  SalaryStructure({
    required this.employeeId,
    required this.baseAnnualCtc,
    required this.monthlyGross,
    required this.basic,
    required this.hra,
    required this.specialAllowance,
    required this.pf,
    required this.tdsEstimated,
    required this.netTakeHome,
  });

  factory SalaryStructure.fromJson(Map<String, dynamic> json) {
    final breakdown = json['breakdown'] as Map<String, dynamic>?;

    final basic = (breakdown?['basic'] as num?)?.toDouble() ??
        (json['basic_salary'] as num?)?.toDouble() ??
        45000.0;
    final hra = (breakdown?['hra'] as num?)?.toDouble() ??
        (json['hra'] as num?)?.toDouble() ??
        18000.0;
    final specialAllowance =
        (breakdown?['special_allowance'] as num?)?.toDouble() ??
            (json['allowances'] as num?)?.toDouble() ??
            7000.0;
    final pf = (breakdown?['pf'] as num?)?.toDouble() ??
        (json['deductions'] as num?)?.toDouble() ??
        (json['provident_fund'] as num?)?.toDouble() ??
        2500.0;
    final tdsEstimated = (breakdown?['tds_estimated'] as num?)?.toDouble() ??
        (json['tax'] as num?)?.toDouble() ??
        (json['tax_deductions'] as num?)?.toDouble() ??
        4500.0;

    final monthlyGross = (json['monthly_gross'] as num?)?.toDouble() ??
        (basic + hra + specialAllowance);
    final netTakeHome = (breakdown?['net_take_home'] as num?)?.toDouble() ??
        (json['net_salary'] as num?)?.toDouble() ??
        (monthlyGross - pf - tdsEstimated);
    final baseAnnualCtc = (json['base_annual_ctc'] as num?)?.toDouble() ??
        (monthlyGross * 12);

    return SalaryStructure(
      employeeId: json['employee_id']?.toString() ?? '',
      baseAnnualCtc: baseAnnualCtc,
      monthlyGross: monthlyGross,
      basic: basic,
      hra: hra,
      specialAllowance: specialAllowance,
      pf: pf,
      tdsEstimated: tdsEstimated,
      netTakeHome: netTakeHome,
    );
  }
}
