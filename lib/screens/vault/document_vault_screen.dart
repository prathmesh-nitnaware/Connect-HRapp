import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/session_service.dart';
import '../../models/document_asset_model.dart';
import '../../providers/document_asset_provider.dart';

class DocumentVaultScreen extends StatefulWidget {
  const DocumentVaultScreen({super.key});

  @override
  State<DocumentVaultScreen> createState() => _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends State<DocumentVaultScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final session = context.read<SessionService>();
    final provider = context.read<DocumentAssetProvider>();
    provider.fetchMyDocuments(token: session.token);
    if (session.isHR) {
      provider.fetchAllAssets(token: session.token);
    } else {
      provider.fetchMyAssets(token: session.token);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();
    final provider = context.watch<DocumentAssetProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault & Asset Management'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.folder_shared), text: 'Document Vault'),
            Tab(icon: Icon(Icons.laptop_chromebook), text: 'Company Assets'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDocumentsTab(provider.documents, theme),
                _buildAssetsTab(provider.assets, session.isHR, theme),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Upload Doc' : (session.isHR ? 'Assign Asset' : 'Report Issue')),
        onPressed: () {
          if (_tabController.index == 0) {
            _showUploadDocDialog(context);
          } else if (session.isHR) {
            _showAssignAssetDialog(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('To report hardware issues, please open a Helpdesk ticket.')),
            );
          }
        },
      ),
    );
  }

  Widget _buildDocumentsTab(List<VaultDocument> docs, ThemeData theme) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('No documents uploaded in vault', style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
              child: Icon(_getDocIcon(doc.category), color: theme.colorScheme.primary),
            ),
            title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${doc.category} • ${doc.fileSize}'),
                Text('Uploaded: ${doc.uploadDate}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: doc.verified ? Colors.green.withOpacity(0.15) : Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(doc.verified ? Icons.verified : Icons.pending, size: 14, color: doc.verified ? Colors.green : Colors.amber.shade800),
                  const SizedBox(width: 4),
                  Text(
                    doc.verified ? 'Verified' : 'Pending',
                    style: TextStyle(color: doc.verified ? Colors.green : Colors.amber.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Viewing secure file: ${doc.fileName}')),
              );
            },
          ),
        );
      },
    );
  }

  IconData _getDocIcon(String category) {
    switch (category.toLowerCase()) {
      case 'contract':
        return Icons.description;
      case 'tax':
        return Icons.receipt_long;
      case 'id proof':
        return Icons.badge;
      case 'offer letter':
      default:
        return Icons.mark_email_read;
    }
  }

  Widget _buildAssetsTab(List<CompanyAsset> assets, bool isHR, ThemeData theme) {
    if (assets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices_other, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('No company assets assigned', style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(_getAssetIcon(asset.type), color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(asset.assetName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(asset.status, style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Asset Tag', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(asset.assetTag, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Serial Number', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(asset.serialNumber, style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Assigned To', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(asset.employeeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getAssetIcon(String type) {
    switch (type.toLowerCase()) {
      case 'laptop':
        return Icons.laptop_mac;
      case 'monitor':
        return Icons.desktop_windows;
      case 'access card':
        return Icons.credit_card;
      default:
        return Icons.devices;
    }
  }

  void _showUploadDocDialog(BuildContext context) {
    final titleController = TextEditingController();
    String category = 'Contract';
    String fileName = 'employment_contract_signed.pdf';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Upload Document to Vault'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Document Title', hintText: 'e.g. Form 16 Tax Document'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['Contract', 'ID Proof', 'Tax', 'Offer Letter', 'Other'].map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => category = val);
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(fileName, style: const TextStyle(fontSize: 12))),
                    TextButton(
                      onPressed: () {
                        setModalState(() => fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}.pdf');
                      },
                      child: const Text('Browse'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                final session = context.read<SessionService>();
                final success = await context.read<DocumentAssetProvider>().uploadDocument({
                  'title': titleController.text.trim(),
                  'category': category,
                  'file_name': fileName,
                  'file_size': '2.4 MB',
                }, token: session.token);

                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Document uploaded securely!' : 'Failed to upload document')),
                  );
                }
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignAssetDialog(BuildContext context) {
    final assetNameController = TextEditingController();
    final tagController = TextEditingController(text: 'AST-${DateTime.now().millisecondsSinceEpoch % 10000}');
    final serialController = TextEditingController(text: 'SN-${DateTime.now().millisecondsSinceEpoch % 999999}');
    final empIdController = TextEditingController(text: 'EMP001');
    final empNameController = TextEditingController(text: 'Prathmesh Nitnaware');
    String type = 'Laptop';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Assign Asset to Employee'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: assetNameController, decoration: const InputDecoration(labelText: 'Asset Name', hintText: 'e.g. MacBook Pro M3 16"')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['Laptop', 'Monitor', 'Access Card', 'Phone', 'Other'].map((t) {
                    return DropdownMenuItem(value: t, child: Text(t));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => type = val);
                  },
                ),
                TextField(controller: tagController, decoration: const InputDecoration(labelText: 'Asset Tag')),
                TextField(controller: serialController, decoration: const InputDecoration(labelText: 'Serial Number')),
                TextField(controller: empIdController, decoration: const InputDecoration(labelText: 'Employee ID')),
                TextField(controller: empNameController, decoration: const InputDecoration(labelText: 'Employee Name')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (assetNameController.text.trim().isEmpty) return;
                final session = context.read<SessionService>();
                final success = await context.read<DocumentAssetProvider>().assignAsset({
                  'asset_name': assetNameController.text.trim(),
                  'asset_tag': tagController.text.trim(),
                  'type': type,
                  'serial_number': serialController.text.trim(),
                  'employee_id': empIdController.text.trim(),
                  'employee_name': empNameController.text.trim(),
                }, token: session.token);

                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Asset assigned successfully!' : 'Failed to assign asset')),
                  );
                }
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }
}
