import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/question.dart';
import '../models/attempt.dart';
import '../theme/app_theme.dart';

/// Screen for viewing and answering a question
class QuestionDetailScreen extends StatefulWidget {
  final Question question;

  const QuestionDetailScreen({super.key, required this.question});

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  final TextEditingController _answerController = TextEditingController();
  final ApiClient _apiClient = ApiClient();
  bool _isSubmitting = false;
  Attempt? _lastAttempt;
  DateTime? _startTime;
  String? _selectedMcqAnswer;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    if (widget.question.questionType == 'mcq' && widget.question.options != null) {
      _selectedMcqAnswer = null;
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    String answer;
    if (widget.question.questionType == 'mcq') {
      if (_selectedMcqAnswer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an answer')),
        );
        return;
      }
      answer = _selectedMcqAnswer!;
    } else {
      if (_answerController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an answer')),
        );
        return;
      }
      answer = _answerController.text.trim();
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final timeTaken = _startTime != null
          ? DateTime.now().difference(_startTime!).inSeconds.toDouble()
          : null;

      final response = await _apiClient.submitAttempt(
        questionId: widget.question.questionId,
        userAnswer: answer,
        timeTaken: timeTaken,
      );

      final attempt = Attempt.fromJson(response);
      setState(() {
        _lastAttempt = attempt;
        _isSubmitting = false;
      });

      _showResultDialog(attempt);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showResultDialog(Attempt attempt) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: attempt.isCorrect
                ? AppTheme.successGradient
                : LinearGradient(
                    colors: [AppTheme.errorColor, AppTheme.errorColor.withOpacity(0.8)],
                  ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                attempt.isCorrect ? Icons.check_circle : Icons.cancel,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                attempt.isCorrect ? 'Correct!' : 'Incorrect',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (attempt.score != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Score: ${(attempt.score! * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Answer:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      attempt.userAnswer,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Correct Answer:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      attempt.correctAnswer,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (attempt.explanation != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Explanation:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        attempt.explanation!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: attempt.isCorrect
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppTheme.successColor;
      case 'medium':
        return AppTheme.warningColor;
      case 'hard':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getQuestionTypeIcon(String type) {
    switch (type) {
      case 'mcq':
        return Icons.radio_button_checked;
      case 'short_answer':
        return Icons.short_text;
      case 'long_answer':
        return Icons.article;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Question'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Type and Difficulty Badges
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getQuestionTypeIcon(widget.question.questionType),
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.question.questionType.toUpperCase().replaceAll('_', ' '),
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(widget.question.difficulty).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.question.difficulty.toUpperCase(),
                    style: TextStyle(
                      color: _getDifficultyColor(widget.question.difficulty),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Question Text
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                widget.question.questionText,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 24),

            // MCQ Options
            if (widget.question.questionType == 'mcq' && widget.question.options != null)
              ...widget.question.options!.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final letter = String.fromCharCode(65 + index); // A, B, C, D
                final isSelected = _selectedMcqAnswer == letter;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedMcqAnswer = letter;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                letter,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppTheme.primaryColor,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

            // Text Input for Short/Long Answer
            if (widget.question.questionType != 'mcq')
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _answerController,
                  decoration: InputDecoration(
                    hintText: widget.question.questionType == 'short_answer'
                        ? 'Enter your answer (1-2 sentences)'
                        : 'Enter your detailed answer',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  maxLines: widget.question.questionType == 'long_answer' ? 10 : 3,
                  enabled: !_isSubmitting && _lastAttempt == null,
                ),
              ),

            const SizedBox(height: 32),

            // Submit Button
            if (_lastAttempt == null)
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Submit Answer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),

            // Result Card
            if (_lastAttempt != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: _lastAttempt!.isCorrect
                      ? AppTheme.successGradient
                      : LinearGradient(
                          colors: [
                            AppTheme.errorColor,
                            AppTheme.errorColor.withOpacity(0.8),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _lastAttempt!.isCorrect
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _lastAttempt!.isCorrect ? 'Correct Answer!' : 'Incorrect',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (_lastAttempt!.explanation != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _lastAttempt!.explanation!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
