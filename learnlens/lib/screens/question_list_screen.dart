import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/question/question_bloc.dart';
import '../models/question.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
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
  String _selectedDifficulty = 'medium';

  @override
  void initState() {
    super.initState();
    context.read<QuestionBloc>().add(LoadQuestions(widget.documentId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Questions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showGenerateDialog(context),
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: BlocBuilder<QuestionBloc, QuestionState>(
        builder: (context, state) {
          if (state is QuestionLoading || state is QuestionInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is QuestionLoaded) {
            if (state.questions.isEmpty) {
              return EmptyState(
                title: 'No Questions Yet',
                message: 'Generate questions to start practicing',
                icon: Icons.quiz_outlined,
                action: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _showGenerateDialog(context),
                    icon: const Icon(Icons.auto_awesome, color: Colors.white),
                    label: const Text(
                      'Generate Questions',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.questions.length,
              itemBuilder: (context, index) {
                final question = state.questions[index];
                return _QuestionCard(question: question);
              },
            );
          } else if (state is QuestionGenerating) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating questions...'),
                ],
              ),
            );
          } else if (state is QuestionGenerated) {
            // Reload questions after generation
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<QuestionBloc>().add(LoadQuestions(widget.documentId));
            });
            return const Center(child: CircularProgressIndicator());
          } else if (state is QuestionError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<QuestionBloc>().add(LoadQuestions(widget.documentId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showGenerateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text('Generate Questions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedQuestionType,
              decoration: const InputDecoration(labelText: 'Question Type'),
              items: const [
                DropdownMenuItem(value: 'mcq', child: Text('Multiple Choice')),
                DropdownMenuItem(value: 'short_answer', child: Text('Short Answer')),
                DropdownMenuItem(value: 'long_answer', child: Text('Long Answer')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedQuestionType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDifficulty,
              decoration: const InputDecoration(labelText: 'Difficulty'),
              items: const [
                DropdownMenuItem(value: 'easy', child: Text('Easy')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'hard', child: Text('Hard')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedDifficulty = value!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () {
                context.read<QuestionBloc>().add(
                      GenerateQuestions(
                        documentId: widget.documentId,
                        questionType: _selectedQuestionType,
                        difficulty: _selectedDifficulty,
                      ),
                    );
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: const Text(
                'Generate',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Question question;

  const _QuestionCard({required this.question});

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

  Color _getTypeColor(String type) {
    switch (type) {
      case 'mcq':
        return AppTheme.primaryColor;
      case 'short_answer':
        return AppTheme.successColor;
      case 'long_answer':
        return AppTheme.accentColor;
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
    final typeColor = _getTypeColor(question.questionType);
    final difficultyColor = _getDifficultyColor(question.difficulty);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuestionDetailScreen(question: question),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getQuestionTypeIcon(question.questionType),
                      color: typeColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            question.questionType.toUpperCase().replaceAll('_', ' '),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: typeColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: difficultyColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            question.difficulty.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: difficultyColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                question.questionText,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

