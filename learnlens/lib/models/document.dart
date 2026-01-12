/// Document model
class Document {
  final String documentId;
  final String userId;
  final String title;
  final String extractedText;
  final String language;
  final DateTime uploadedAt;
  final String status;

  Document({
    required this.documentId,
    required this.userId,
    required this.title,
    required this.extractedText,
    required this.language,
    required this.uploadedAt,
    required this.status,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      documentId: json['document_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      extractedText: json['extracted_text']?.toString() ?? '',
      language: json['language']?.toString() ?? 'en',
      uploadedAt: _parseDateTime(json['uploaded_at']),
      status: json['status']?.toString() ?? 'uploaded',
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        // Try parsing with different formats
        if (value.contains('T')) {
          return DateTime.parse(value);
        }
        return DateTime.now();
      }
    }
    if (value is DateTime) return value;
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'document_id': documentId,
      'user_id': userId,
      'title': title,
      'extracted_text': extractedText,
      'language': language,
      'uploaded_at': uploadedAt.toIso8601String(),
      'status': status,
    };
  }
}

