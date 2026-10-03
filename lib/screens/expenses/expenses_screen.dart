import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/session_service.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final session = context.read<SessionService>();
    final provider = context.read<ExpenseProvider>();
    if (session.isHR) {
      provider.fetchAllExpenses(token: session.token);
    } else {
      provider.fetchMyExpenses(token: session.token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();
    final provider = context.watch<ExpenseProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(session.isHR ? 'Employee Expense Claims' : 'My Reimbursements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.expenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_outlined, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      const SizedBox(height: 16),
                      Text('No expense claims recorded', style: theme.textTheme.titleMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.expenses.length,
                  itemBuilder: (context, index) {
                    final item = provider.expenses[index];
                    return _buildExpenseCard(item, session.isHR, theme);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Claim Expense'),
        onPressed: () => _showSubmitExpenseDialog(context),
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseClaim item, bool isHR, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${item.category} • ${item.employeeName}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                _buildStatusBadge(item.status),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Amount Claimed', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      '₹ ${item.amount.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Date of Expense', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(item.date, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            if (item.reviewerComment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'HR Note: ${item.reviewerComment}',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
            if (isHR && item.status.toLowerCase() == 'pending') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () => _showReviewDialog(item, 'Rejected'),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _showReviewDialog(item, 'Approved'),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status.toLowerCase() == 'approved') color = Colors.green;
    if (status.toLowerCase() == 'rejected') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showSubmitExpenseDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String category = 'Travel';
    String date = DateTime.now().toIso8601String().split('T').first;
    String receiptName = 'hotel_flight_receipt.pdf';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Submit Reimbursement Claim'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Expense Title', hintText: 'e.g. Client Dinner / Flight to Pune')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ['Travel', 'Meals', 'Equipment', 'Office Supplies', 'Other'].map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),

                  onChanged: (val) {
                    if (val != null) setModalState(() => category = val);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount (₹)'),
                  keyboardType: TextInputType.number,
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
                      const Icon(Icons.attach_file, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(child: Text(receiptName, style: const TextStyle(fontSize: 12))),
                      TextButton(
                        onPressed: () {
                          setModalState(() => receiptName = 'tax_invoice_${DateTime.now().millisecondsSinceEpoch}.pdf');
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty || amountController.text.trim().isEmpty) return;
                final session = context.read<SessionService>();
                final success = await context.read<ExpenseProvider>().submitExpense({
                  'title': titleController.text.trim(),
                  'category': category,
                  'amount': double.tryParse(amountController.text.trim()) ?? 0.0,
                  'date': date,
                  'receipt_url': 'https://storage.enterprise-connect.com/receipts/$receiptName',
                }, token: session.token);

                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Expense claim submitted!' : 'Failed to submit expense')),
                  );
                }
              },
              child: const Text('Submit Claim'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewDialog(ExpenseClaim item, String newStatus) {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$newStatus Expense Claim'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Claim for ₹${item.amount.toStringAsFixed(0)} by ${item.employeeName}'),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(labelText: 'Reviewer Comment (Optional)', hintText: 'e.g. Approved per travel policy limits'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final session = context.read<SessionService>();
              await context.read<ExpenseProvider>().updateStatus(
                    item.id,
                    newStatus,
                    comment: commentController.text.trim(),
                    token: session.token,
                  );
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Expense claim marked as $newStatus')),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
