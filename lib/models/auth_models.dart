class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class LoginResponse {
  final String? token;
  final String? role;
  final String? message;

  LoginResponse({this.token, this.role, this.message});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String?,
      role: json['role'] as String?,
      message: json['message'] as String?,
    );
  }
}

class SignupRequest {
  final String name;
  final String email;
  final String password;
  final String role;
  final String? department;

  SignupRequest({
    required this.name,
    required this.email,
    required this.password,
    this.role = 'employee',
    this.department,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        if (department != null) 'department': department,
      };
}

class SignupResponse {
  final String? message;

  SignupResponse({this.message});

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
      message: json['message'] as String?,
    );
  }
}
