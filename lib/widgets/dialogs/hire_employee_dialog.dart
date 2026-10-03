import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hr_provider.dart';
import '../custom_text_field.dart';

class HireEmployeeDialog extends StatefulWidget {
  const HireEmployeeDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => const HireEmployeeDialog(),
    );
  }

  @override
  State<HireEmployeeDialog> createState() => _HireEmployeeDialogState();
}

class _HireEmployeeDialogState extends State<HireEmployeeDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'employee';
  String _selectedDepartment = 'Engineering';
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _departments = [
    'Engineering',
    'IT',
    'HR',
    'Sales',
    'Marketing',
    'Design',
    'Operations',
    'Unassigned',
  ];

  final List<String> _roles = ['employee', 'HR'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill all required fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final hrProvider = context.read<HRProvider>();
    final success = await hrProvider.createEmployee(
      name: name,
      email: email,
      password: password,
      role: _selectedRole,
      department: _selectedDepartment,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = hrProvider.statusMessage ?? 'Failed to hire employee';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Hire New Employee',
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              controller: _nameController,
              label: 'Full Name',
              prefixIcon: const Icon(Icons.person_outline),
              onChanged: (_) => setState(() => _errorMessage = null),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
              onChanged: (_) => setState(() => _errorMessage = null),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _passwordController,
              label: 'Temporary Password',
              isPassword: true,
              prefixIcon: const Icon(Icons.lock_outline),
              onChanged: (_) => setState(() => _errorMessage = null),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedDepartment,
              decoration: const InputDecoration(
                labelText: 'Department',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              items: _departments.map((dept) {
                return DropdownMenuItem(value: dept, child: Text(dept));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedDepartment = val);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: _roles.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role == 'HR' ? 'HR Administrator' : 'Regular Employee'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedRole = val);
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Hire'),
        ),
      ],
    );
  }
}
