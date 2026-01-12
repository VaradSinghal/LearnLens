/// Attempt model
class Attempt {
  final String attemptId;
  final String userId;
  final String questionId;
  final String userAnswer;
  final bool isCorrect;
  final double? score;
  final double? timeTaken;
  final DateTime attemptedAt;
  final String correctAnswer;
  final String? explanation;

  Attempt({
    required this.attemptId,
    required this.userId,
    required this.questionId,
    required this.userAnswer,
    required this.isCorrect,
    this.score,
    this.timeTaken,
    required this.attemptedAt,
    required this.correctAnswer,
    this.explanation,
  });

  factory Attempt.fromJson(Map<String, dynamic> json) {
    return Attempt(
      attemptId: json['attempt_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      questionId: json['question_id']?.toString() ?? '',
      userAnswer: json['user_answer']?.toString() ?? '',
      isCorrect: json['is_correct'] == true || json['is_correct'] == 'true',
      score: json['score'] != null 
          ? (json['score'] is num ? json['score'].toDouble() : double.tryParse(json['score'].toString()))
          : null,
      timeTaken: json['time_taken'] != null
          ? (json['time_taken'] is num ? json['time_taken'].toDouble() : double.tryParse(json['time_taken'].toString()))
          : null,
      attemptedAt: _parseDateTime(json['attempted_at']),
      correctAnswer: json['correct_answer']?.toString() ?? '',
      explanation: json['explanation']?.toString(),
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
      'attempt_id': attemptId,
      'user_id': userId,
      'question_id': questionId,
      'user_answer': userAnswer,
      'is_correct': isCorrect,
      'score': score,
      'time_taken': timeTaken,
      'attempted_at': attemptedAt.toIso8601String(),
      'correct_answer': correctAnswer,
      'explanation': explanation,
    };
  }
}

