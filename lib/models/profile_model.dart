class ProfileResponse {
  final String name;
  final String email;
  final String role;
  final String department;

  ProfileResponse({
    required this.name,
    required this.email,
    required this.role,
    required this.department,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'employee',
      department: json['department'] as String? ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'role': role,
        'department': department,
      };
}
