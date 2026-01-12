import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/empty_state.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ApiClient _apiClient = ApiClient();
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final analytics = await _apiClient.getPerformanceAnalytics();
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyState(
                  title: 'Error Loading Analytics',
                  message: _error!,
                  icon: Icons.error_outline,
                  action: ElevatedButton(
                    onPressed: _loadAnalytics,
                    child: const Text('Retry'),
                  ),
                )
              : _analytics == null || (_analytics!['total_attempts'] as int? ?? 0) == 0
                  ? EmptyState(
                      title: 'No Data Yet',
                      message: 'Complete some questions to see your analytics',
                      icon: Icons.analytics_outlined,
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAnalytics,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Overall Stats
                            Row(
                              children: [
                                Expanded(
                                  child: StatCard(
                                    title: 'Total Attempts',
                                    value: '${_analytics!['total_attempts']}',
                                    icon: Icons.quiz,
                                    gradient: AppTheme.primaryGradient,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: StatCard(
                                    title: 'Accuracy',
                                    value: '${((_analytics!['overall_accuracy'] as num? ?? 0) * 100).toStringAsFixed(1)}%',
                                    subtitle: 'Overall',
                                    icon: Icons.trending_up,
                                    gradient: AppTheme.successGradient,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Difficulty Stats
                            if (_analytics!['difficulty_stats'] != null &&
                                (_analytics!['difficulty_stats'] as List).isNotEmpty)
                              ...(_analytics!['difficulty_stats'] as List).map((stat) {
                                final difficulty = stat['difficulty'] as String;
                                final accuracy = (stat['accuracy'] as num? ?? 0) * 100;
                                final total = stat['total_questions'] as int? ?? 0;
                                final correct = stat['correct_answers'] as int? ?? 0;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getDifficultyColor(difficulty)
                                                    .withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                difficulty.toUpperCase(),
                                                style: TextStyle(
                                                  color: _getDifficultyColor(difficulty),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${accuracy.toStringAsFixed(1)}%',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: _getDifficultyColor(difficulty),
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _StatItem(
                                                label: 'Correct',
                                                value: '$correct',
                                                color: AppTheme.successColor,
                                              ),
                                            ),
                                            Expanded(
                                              child: _StatItem(
                                                label: 'Total',
                                                value: '$total',
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                            if (stat['avg_time'] != null)
                                              Expanded(
                                                child: _StatItem(
                                                  label: 'Avg Time',
                                                  value: '${(stat['avg_time'] as num).toStringAsFixed(1)}s',
                                                  color: AppTheme.accentColor,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            // Topic Accuracy
                            if (_analytics!['topic_accuracy'] != null &&
                                (_analytics!['topic_accuracy'] as List).isNotEmpty) ...[
                              Text(
                                'Topic Performance',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              ...(_analytics!['topic_accuracy'] as List).map((topic) {
                                final topicName = topic['topic'] as String;
                                final accuracy = (topic['accuracy'] as num? ?? 0) * 100;
                                final total = topic['total_questions'] as int? ?? 0;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              topicName,
                                              style: Theme.of(context).textTheme.titleMedium,
                                            ),
                                            Text(
                                              '${accuracy.toStringAsFixed(1)}%',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: accuracy >= 70
                                                        ? AppTheme.successColor
                                                        : accuracy >= 50
                                                            ? AppTheme.warningColor
                                                            : AppTheme.errorColor,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: accuracy / 100,
                                            backgroundColor: Colors.grey.shade200,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              accuracy >= 70
                                                  ? AppTheme.successColor
                                                  : accuracy >= 50
                                                      ? AppTheme.warningColor
                                                      : AppTheme.errorColor,
                                            ),
                                            minHeight: 8,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$total questions',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                            // Weak Areas
                            if (_analytics!['weak_areas'] != null &&
                                (_analytics!['weak_areas'] as List).isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Card(
                                color: AppTheme.errorColor.withOpacity(0.1),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            color: AppTheme.errorColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Areas to Improve',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.errorColor,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      ...(_analytics!['weak_areas'] as List).map((area) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.arrow_right,
                                                size: 16,
                                                color: AppTheme.errorColor,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  area as String,
                                                  style: Theme.of(context).textTheme.bodyMedium,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
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
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

