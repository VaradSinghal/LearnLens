/// Question model
class Question {
  final String questionId;
  final String documentId;
  final String questionType; // 'mcq', 'short_answer', 'long_answer'
  final String difficulty; // 'easy', 'medium', 'hard'
  final String questionText;
  final String correctAnswer;
  final String? explanation;
  final List<String>? options; // For MCQ
  final DateTime createdAt;
  final List<String> chunkIds;

  Question({
    required this.questionId,
    required this.documentId,
    required this.questionType,
    required this.difficulty,
    required this.questionText,
    required this.correctAnswer,
    this.explanation,
    this.options,
    required this.createdAt,
    required this.chunkIds,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionId: json['question_id']?.toString() ?? '',
      documentId: json['document_id']?.toString() ?? '',
      questionType: json['question_type']?.toString() ?? 'mcq',
      difficulty: json['difficulty']?.toString() ?? 'medium',
      questionText: json['question_text']?.toString() ?? '',
      correctAnswer: json['correct_answer']?.toString() ?? '',
      explanation: json['explanation']?.toString(),
      options: json['options'] != null 
          ? List<String>.from(json['options'].map((x) => x.toString()))
          : null,
      createdAt: _parseDateTime(json['created_at']),
      chunkIds: json['chunk_ids'] != null
          ? List<String>.from(json['chunk_ids'].map((x) => x.toString()))
          : [],
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    if (value is DateTime) return value;
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'document_id': documentId,
      'question_type': questionType,
      'difficulty': difficulty,
      'question_text': questionText,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'options': options,
      'created_at': createdAt.toIso8601String(),
      'chunk_ids': chunkIds,
    };
  }
}

