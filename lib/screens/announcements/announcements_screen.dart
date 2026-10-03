import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/session_service.dart';
import '../../models/announcement_model.dart';
import '../../providers/announcement_provider.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = context.read<SessionService>();
      context.read<AnnouncementProvider>().fetchAnnouncements(token: session.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();
    final provider = context.watch<AnnouncementProvider>();
    final theme = Theme.of(context);

    final filtered = provider.announcements.where((a) {
      if (_selectedCategory == 'All') return true;
      return a.category.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();

    // Sort: pinned first, then by date
    filtered.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements & Notice Board'),
        actions: [
          if (session.isHR)
            IconButton(
              icon: const Icon(Icons.campaign),
              tooltip: 'Post Announcement',
              onPressed: () => _showCreateAnnouncementDialog(context),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.fetchAnnouncements(token: session.token),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: ['All', 'General', 'Policy', 'Holiday', 'Emergency'].map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Announcements List
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mark_chat_read_outlined, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                            const SizedBox(height: 16),
                            Text('No announcements found', style: theme.textTheme.titleMedium),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isRead = session.currentUser != null && item.readBy.contains(session.currentUser!.id);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            elevation: item.isPinned ? 3 : 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: item.isPinned
                                  ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                                  : BorderSide.none,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (item.isPinned) ...[
                                        Icon(Icons.push_pin, size: 18, color: theme.colorScheme.primary),
                                        const SizedBox(width: 6),
                                      ],
                                      _buildCategoryBadge(item.category),
                                      const Spacer(),
                                      Text(
                                        item.createdAt.contains('T') ? item.createdAt.split('T').first : item.createdAt,
                                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    item.title,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.content,
                                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                                            child: Icon(Icons.person, size: 14, color: theme.colorScheme.primary),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'By ${item.author}',
                                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          if (!session.isHR && !isRead)
                                            TextButton.icon(
                                              icon: const Icon(Icons.check_circle_outline, size: 18),
                                              label: const Text('Mark Read'),
                                              onPressed: () {
                                                if (session.currentUser != null) {
                                                  provider.markAsRead(item.id, session.currentUser!.id, token: session.token);
                                                }
                                              },
                                            ),
                                          if (isRead)
                                            const Row(
                                              children: [
                                                Icon(Icons.check, size: 16, color: Colors.green),
                                                SizedBox(width: 4),
                                                Text('Read', style: TextStyle(color: Colors.green, fontSize: 12)),
                                              ],
                                            ),
                                          if (session.isHR)
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                                              onPressed: () => provider.deleteAnnouncement(item.id, token: session.token),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    Color bg = Colors.blue.withOpacity(0.15);
    Color text = Colors.blue.shade800;

    if (category.toLowerCase() == 'policy') {
      bg = Colors.purple.withOpacity(0.15);
      text = Colors.purple.shade800;
    } else if (category.toLowerCase() == 'holiday') {
      bg = Colors.green.withOpacity(0.15);
      text = Colors.green.shade800;
    } else if (category.toLowerCase() == 'emergency') {
      bg = Colors.red.withOpacity(0.15);
      text = Colors.red.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showCreateAnnouncementDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String category = 'General';
    bool isPinned = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Post Company Announcement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Headline / Title', hintText: 'e.g. Annual Town Hall 2026'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ['General', 'Policy', 'Holiday', 'Emergency'].map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Announcement Details', hintText: 'Provide complete details for staff...'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pin to top of feed'),
                  value: isPinned,
                  onChanged: (val) => setModalState(() => isPinned = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) return;
                final session = context.read<SessionService>();
                final success = await context.read<AnnouncementProvider>().createAnnouncement({
                  'title': titleController.text.trim(),
                  'content': contentController.text.trim(),
                  'category': category,
                  'is_pinned': isPinned,
                }, token: session.token);

                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Announcement published!' : 'Failed to publish announcement')),
                  );
                }
              },
              child: const Text('Broadcast'),
            ),
          ],
        ),
      ),
    );
  }
}
