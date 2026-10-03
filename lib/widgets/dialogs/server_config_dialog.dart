import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/session_service.dart';

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late final TextEditingController _urlController;
  final SessionService _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: _sessionService.customBaseUrl ?? ApiConstants.defaultBaseUrl,
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _urlController.text.trim();
    await _sessionService.setCustomBaseUrl(text.isEmpty ? null : text);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Base URL updated to: ${_sessionService.customBaseUrl ?? ApiConstants.defaultBaseUrl}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _reset() async {
    await _sessionService.setCustomBaseUrl(null);
    if (mounted) {
      _urlController.text = ApiConstants.defaultBaseUrl;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.settings_outlined),
          SizedBox(width: 8),
          Text('Server Configuration'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configure the backend REST API Base URL. Android emulator uses 10.0.2.2:5000, physical devices use your local PC IP.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: 'API Base URL',
              hintText: 'http://10.0.2.2:5000/api/',
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Reset to default',
                onPressed: _reset,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
