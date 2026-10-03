class Announcement {
  final String id;
  final String title;
  final String content;
  final String category;
  final bool isPinned;
  final String author;
  final String createdAt;
  final List<String> readBy;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.isPinned,
    required this.author,
    required this.createdAt,
    required this.readBy,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      isPinned: json['is_pinned'] == true,
      author: json['author']?.toString() ?? 'HR Team',
      createdAt: json['created_at']?.toString() ?? '',
      readBy: (json['read_by'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'category': category,
        'is_pinned': isPinned,
        'author': author,
        'created_at': createdAt,
        'read_by': readBy,
      };
}
