class HREmployee {
  final String id;
  final String name;
  final String email;
  final String role;
  final String department;

  HREmployee({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
  });

  factory HREmployee.fromJson(Map<String, dynamic> json) {
    return HREmployee(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'employee',
      department: json['department'] as String? ?? 'Unassigned',
    );
  }

  HREmployee copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? department,
  }) {
    return HREmployee(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'department': department,
      };
}

class HREmployeeUpdateRequest {
  final String? department;
  final String? role;

  HREmployeeUpdateRequest({this.department, this.role});

  Map<String, dynamic> toJson() => {
        if (department != null) 'department': department,
        if (role != null) 'role': role,
      };
}
