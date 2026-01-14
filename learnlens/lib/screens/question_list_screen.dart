import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../theme/app_theme.dart';
import '../bloc/question/question_bloc.dart';
import '../models/question.dart';
import '../widgets/empty_state.dart';
import '../core/api_client.dart';
import 'question_detail_screen.dart';

/// Screen displaying questions for a document
class QuestionListScreen extends StatefulWidget {
  final String documentId;

  const QuestionListScreen({super.key, required this.documentId});

  @override
  State<QuestionListScreen> createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen> {
  String _selectedQuestionType = 'mcq';
  final ApiClient _apiClient = ApiClient();
  Map<String, bool> _attemptStatus = {}; // questionId -> hasAttempt
  bool _loadingAttempts = false;

  @override
  void initState() {
    super.initState();
    context.read<QuestionBloc>().add(LoadQuestions(widget.documentId));
    _loadAttemptStatus();
  }

  Future<void> _loadAttemptStatus() async {
    if (!mounted) return;
    
    setState(() {
      _loadingAttempts = true;
    });
    try {
      final attempts = await _apiClient.getAttempts();
      final statusMap = <String, bool>{};
      for (var attempt in attempts) {
        final questionId = attempt['question_id']?.toString();
        if (questionId != null) {
          statusMap[questionId] = true;
        }
      }
      if (mounted) {
        setState(() {
          _attemptStatus = statusMap;
          _loadingAttempts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingAttempts = false;
        });
      }
    }
  }

  void _refreshQuestions() {
    if (!mounted) return;
    context.read<QuestionBloc>().add(LoadQuestions(widget.documentId));
    _loadAttemptStatus();
  }

  void _generateQuestions() {
    context.read<QuestionBloc>().add(
          GenerateQuestions(
            documentId: widget.documentId,
            questionType: _selectedQuestionType,
            difficulty: 'medium',
            numQuestions: 5,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor.withOpacity(0.8),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Symbols.arrow_back_ios, size: 20),
                            color: AppTheme.textPrimary,
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const SizedBox(width: 8),
                              Text(
                                'LearnLens',
                                style: GoogleFonts.manrope(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Main content
                Expanded(
                  child: BlocConsumer<QuestionBloc, QuestionState>(
                listener: (context, state) {
                  if (state is QuestionGenerated) {
                    // Reload questions after generation
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _refreshQuestions();
                    });
                  } else if (state is QuestionError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is QuestionLoading || state is QuestionInitial) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    );
                  } else if (state is QuestionGenerating) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Generating questions...',
                            style: GoogleFonts.manrope(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (state is QuestionLoaded) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        _refreshQuestions();
                        // Wait a bit for the refresh to complete
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      color: AppTheme.primaryColor,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Question Engine Section
                          _buildQuestionEngineSection(state.questions.isEmpty),
                          const SizedBox(height: 32),
                          // Generated List Header
                          if (state.questions.isNotEmpty) ...[
                            _buildListHeader(),
                            const SizedBox(height: 16),
                            // Question Cards
                            ...state.questions.asMap().entries.map((entry) {
                              final index = entry.key;
                              final question = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _QuestionCard(
                                  question: question,
                                  index: index + 1,
                                  totalQuestions: state.questions.length,
                                  hasAttempt: _attemptStatus[question.questionId] ?? false,
                                ),
                              );
                            }),
                            const SizedBox(height: 100), // Space for bottom indicator
                          ] else ...[
                            const SizedBox(height: 100),
                          ],
                        ],
                        ),
                      ),
                    );
                  } else if (state is QuestionError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Symbols.error,
                            size: 64,
                            color: AppTheme.errorColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${state.message}',
                            style: GoogleFonts.manrope(
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<QuestionBloc>().add(LoadQuestions(widget.documentId));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.black,
                            ),
                            child: Text(
                              'Retry',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
              ],
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildQuestionEngineSection(bool isEmpty) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Symbols.auto_awesome,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question Engine',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'AI-optimized assessment',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Assessment Format Toggle
          Text(
            'ASSESSMENT FORMAT',
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: _buildFormatToggle(
                    label: 'MCQs',
                    isSelected: _selectedQuestionType == 'mcq',
                    onTap: () => setState(() => _selectedQuestionType = 'mcq'),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildFormatToggle(
                    label: 'Short Answer',
                    isSelected: _selectedQuestionType == 'short_answer',
                    onTap: () => setState(() => _selectedQuestionType = 'short_answer'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Generate Button
          Material(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _generateQuestions,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Symbols.bolt,
                      color: Colors.black,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'GENERATE AI QUESTIONS',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'AI will automatically generate a set of optimized questions based on your context.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatToggle({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildListHeader() {
    return Row(
      children: [
        Text(
          'GENERATED LIST',
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ],
    );
  }


}

class _QuestionCard extends StatelessWidget {
  final Question question;
  final int index;
  final int totalQuestions;
  final bool hasAttempt;

  const _QuestionCard({
    required this.question,
    required this.index,
    required this.totalQuestions,
    required this.hasAttempt,
  });

  String _getStatus() {
    if (hasAttempt) return 'Completed';
    if (index == 1) return 'Pending';
    return 'Not Started';
  }

  Color _getStatusColor() {
    final status = _getStatus();
    if (status == 'Completed') return AppTheme.successColor;
    if (status == 'Pending') return AppTheme.primaryColor;
    return AppTheme.textSecondary;
  }

  String _getDifficultyText() {
    return question.difficulty.substring(0, 1).toUpperCase() +
        question.difficulty.substring(1);
  }

  int _getEstimatedTime() {
    // Estimate time based on difficulty
    switch (question.difficulty.toLowerCase()) {
      case 'easy':
        return 1;
      case 'medium':
        return 2;
      case 'hard':
        return 3;
      default:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _getStatus();
    final statusColor = _getStatusColor();
    final isPending = status == 'Pending';

    return GestureDetector(
      onTap: () async {
        // Get the parent state to access documentId and refresh method
        final parentState = context.findAncestorStateOfType<_QuestionListScreenState>();
        if (parentState == null) return;
        
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuestionDetailScreen(
              question: question,
              questionIndex: index,
              totalQuestions: totalQuestions,
              documentId: parentState.widget.documentId,
            ),
          ),
        );
        // Refresh if an attempt was submitted
        if (result == true) {
          parentState._refreshQuestions();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with badge and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'MCQ #$index',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : AppTheme.textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isPending
                          ? AppTheme.primaryColor.withOpacity(0.2)
                          : AppTheme.textSecondary.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status.toUpperCase(),
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Question text
            Text(
              question.questionText,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            // Footer with time, difficulty, and chevron
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.05),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_getEstimatedTime()} min',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.bar_chart,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getDifficultyText(),
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Symbols.chevron_right,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
