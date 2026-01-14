import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/api_client.dart';
import '../models/question.dart';
import '../models/attempt.dart';
import 'question_list_screen.dart';

// Design colors matching the HTML
const Color primaryColor = Color(0xFFA65EED);
const Color backgroundColor = Color(0xFF1A1A1A);
const Color glassBg = Color.fromRGBO(48, 48, 48, 0.45);
const Color glassBorder = Color.fromRGBO(212, 212, 212, 0.15);
const Color correctGlow = Color(0xFF4ADE80);
const Color incorrectGlow = Color(0xFFF87171);
const Color mutedText = Color(0xFFA0A0A0);

/// Screen for viewing and answering a question
class QuestionDetailScreen extends StatefulWidget {
  final Question question;
  final int? questionIndex;
  final int? totalQuestions;
  final String? documentId;

  const QuestionDetailScreen({
    super.key,
    required this.question,
    this.questionIndex,
    this.totalQuestions,
    this.documentId,
  });

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
          SnackBar(
            content: const Text('Please select an answer'),
            backgroundColor: incorrectGlow,
          ),
        );
        return;
      }
      // Send the letter (A, B, C, D) instead of full option text
      // Backend expects the letter to match against correct_answer
      answer = _selectedMcqAnswer!;
    } else {
      if (_answerController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please enter an answer'),
            backgroundColor: incorrectGlow,
          ),
        );
        return;
      }
      answer = _answerController.text.trim();
    }

    if (!mounted) return;
    
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
      if (mounted) {
        setState(() {
          _lastAttempt = attempt;
          _isSubmitting = false;
        });
        
        // Show success message with more detail
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  attempt.isCorrect ? Icons.check_circle : Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    attempt.isCorrect 
                        ? 'Correct! Well done!' 
                        : 'Incorrect. Check the explanation below.',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: attempt.isCorrect ? correctGlow : incorrectGlow,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: incorrectGlow,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _getKeyDifferences() {
    if (_lastAttempt == null || _lastAttempt!.explanation == null) {
      return '';
    }
    // Use explanation as key differences for now
    return _lastAttempt!.explanation!;
  }

  @override
  Widget build(BuildContext context) {
    final showReview = _lastAttempt != null;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Review Details',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer for balance
                ],
              ),
            ),
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question number indicator
                    if (widget.questionIndex != null && widget.totalQuestions != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 32, bottom: 8),
                        child: Text(
                          'Question ${widget.questionIndex.toString().padLeft(2, '0')} of ${widget.totalQuestions}',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    // Question text
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        widget.question.questionText,
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ),
                    // Separator
                    Container(
                      height: 1,
                      margin: const EdgeInsets.only(bottom: 24),
                      color: const Color(0xFFD4D4D4).withOpacity(0.2),
                    ),
                    // Answer Input Section (shown before submission, or for non-MCQ in review mode)
                    if (!showReview || widget.question.questionType != 'mcq')
                      _buildAnswerInputSection(),
                    // Review Section (shown after submission)
                    if (showReview) ...[
                      if (widget.question.questionType == 'mcq') 
                        const SizedBox(height: 0)
                      else
                        const SizedBox(height: 24),
                      _buildReviewSection(),
                    ],
                    const SizedBox(height: 100), // Space for bottom actions
                  ],
                ),
              ),
            ),
            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.05),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  if (showReview)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Return true to indicate an attempt was submitted
                          Navigator.pop(context, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Next Question',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitAnswer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
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
                            : Text(
                                'Submit Answer',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Back to List',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: mutedText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewSection() {
    final isCorrect = _lastAttempt!.isCorrect;
    final statusColor = isCorrect ? correctGlow : incorrectGlow;
    
    // For MCQ, get the correct option text
    String correctAnswerText = _lastAttempt!.correctAnswer;
    if (widget.question.questionType == 'mcq' && widget.question.options != null) {
      try {
        final correctLetter = _lastAttempt!.correctAnswer.trim().toUpperCase();
        if (correctLetter.length == 1 && correctLetter.codeUnitAt(0) >= 65 && correctLetter.codeUnitAt(0) <= 68) {
          final index = correctLetter.codeUnitAt(0) - 65; // A=0, B=1, C=2, D=3
          if (index < widget.question.options!.length) {
            correctAnswerText = '${correctLetter}. ${widget.question.options![index]}';
          }
        }
      } catch (e) {
        // Fallback to showing the letter if parsing fails
        correctAnswerText = 'Correct Answer: ${_lastAttempt!.correctAnswer}';
      }
    }
    
    // For MCQ, get the user's selected option text
    String userAnswerText = _lastAttempt!.userAnswer;
    if (widget.question.questionType == 'mcq' && widget.question.options != null) {
      try {
        final userLetter = _lastAttempt!.userAnswer.trim().toUpperCase();
        if (userLetter.length == 1 && userLetter.codeUnitAt(0) >= 65 && userLetter.codeUnitAt(0) <= 68) {
          final index = userLetter.codeUnitAt(0) - 65;
          if (index < widget.question.options!.length) {
            userAnswerText = '${userLetter}. ${widget.question.options![index]}';
          }
        }
      } catch (e) {
        // Keep original if parsing fails
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Result Header
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RESULT',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: mutedText,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: statusColor.withOpacity(0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: statusColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCorrect ? 'CORRECT' : 'INCORRECT',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // For MCQ, show options with highlighting
        if (widget.question.questionType == 'mcq' && widget.question.options != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'ANSWER REVIEW',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: mutedText,
                letterSpacing: 1.5,
              ),
            ),
          ),
          ...widget.question.options!.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final letter = String.fromCharCode(65 + index); // A, B, C, D
            final isUserSelected = _lastAttempt!.userAnswer.trim().toUpperCase() == letter;
            final isCorrectOption = _lastAttempt!.correctAnswer.trim().toUpperCase() == letter;
            
            Color? borderColor;
            Color? bgColor;
            IconData? icon;
            Color? iconColor;
            
            if (isCorrectOption) {
              borderColor = correctGlow;
              bgColor = correctGlow.withOpacity(0.15);
              icon = Icons.check_circle;
              iconColor = correctGlow;
            } else if (isUserSelected && !isCorrectOption) {
              borderColor = incorrectGlow;
              bgColor = incorrectGlow.withOpacity(0.15);
              icon = Icons.cancel;
              iconColor = incorrectGlow;
            } else {
              borderColor = glassBorder;
              bgColor = glassBg;
            }
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(
                        color: borderColor!,
                        width: isCorrectOption || isUserSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isCorrectOption 
                                ? correctGlow 
                                : (isUserSelected ? incorrectGlow : Colors.white.withOpacity(0.05)),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              letter,
                              style: GoogleFonts.manrope(
                                color: isCorrectOption || isUserSelected ? Colors.white : mutedText,
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
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: (isCorrectOption || isUserSelected) ? FontWeight.w600 : FontWeight.normal,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (icon != null)
                          Icon(
                            icon,
                            color: iconColor,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          // Explanation if available
          if (_lastAttempt!.explanation != null && _lastAttempt!.explanation!.isNotEmpty) ...[
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: glassBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: glassBorder,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 18,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'EXPLANATION',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _lastAttempt!.explanation!,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ] else ...[
          // Comparison Cards for non-MCQ questions
          Column(
            children: [
              // Your Answer Card
              _buildAnswerCard(
                label: 'Your Answer',
                icon: Icons.person,
                answer: userAnswerText,
                isCorrect: false,
              ),
              const SizedBox(height: 20),
              // Expected Answer Card
              _buildAnswerCard(
                label: 'Correct Answer',
                icon: Icons.verified_user,
                answer: correctAnswerText,
                isCorrect: true,
              ),
            ],
          ),
          // Key Differences (for short answer questions)
          if (_getKeyDifferences().isNotEmpty) ...[
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KEY DIFFERENCES',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: mutedText,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getKeyDifferences(),
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: mutedText,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildAnswerCard({
    required String label,
    required IconData icon,
    required String answer,
    required bool isCorrect,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: glassBg,
            borderRadius: BorderRadius.circular(12),
            border: isCorrect
                ? Border(
                    left: BorderSide(
                      color: correctGlow.withOpacity(0.6),
                      width: 4,
                    ),
                    top: BorderSide(color: glassBorder, width: 1),
                    right: BorderSide(color: glassBorder, width: 1),
                    bottom: BorderSide(color: glassBorder, width: 1),
                  )
                : Border.all(
                    color: glassBorder,
                    width: 1,
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isCorrect ? correctGlow : mutedText,
              ),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? correctGlow : mutedText,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            answer,
            style: GoogleFonts.manrope(
              fontSize: 16,
              color: Colors.white,
              height: 1.5,
            ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerInputSection() {
    final isReviewMode = _lastAttempt != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // MCQ Options
        if (widget.question.questionType == 'mcq' && widget.question.options != null)
          ...widget.question.options!.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final letter = String.fromCharCode(65 + index); // A, B, C, D
            final isSelected = _selectedMcqAnswer == letter;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isReviewMode ? null : () {
                    setState(() {
                      _selectedMcqAnswer = letter;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor.withOpacity(0.15)
                              : glassBg,
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : glassBorder,
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
                                    ? primaryColor
                                    : Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  letter,
                                  style: GoogleFonts.manrope(
                                    color: isSelected ? Colors.white : mutedText,
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
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected ? Colors.white : mutedText,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.radio_button_checked,
                                color: primaryColor,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),

        // Text Input for Short/Long Answer
        if (widget.question.questionType != 'mcq')
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: glassBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: glassBorder,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _answerController,
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.question.questionType == 'short_answer'
                        ? 'Enter your answer (1-2 sentences)'
                        : 'Enter your detailed answer',
                    hintStyle: GoogleFonts.manrope(
                      color: mutedText,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  maxLines: widget.question.questionType == 'long_answer' ? 10 : 3,
                  enabled: !_isSubmitting && !isReviewMode,
                  readOnly: isReviewMode,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
