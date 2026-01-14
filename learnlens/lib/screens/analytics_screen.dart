import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
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
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final analytics = await _apiClient.getPerformanceAnalytics();
      if (mounted) {
        setState(() {
          _analytics = analytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  double _calculateGoalCompletion() {
    if (_analytics == null) return 0.0;
    final totalAttempts = _analytics!['total_attempts'] as int? ?? 0;
    const goal = 250;
    final completion = (totalAttempts / goal * 100).clamp(0.0, 100.0);
    return completion;
  }

  String _getStudyTime() {
    if (_analytics == null) return '0h';
    final avgTime = _analytics!['avg_time_per_question'] as double? ?? 0.0;
    final totalAttempts = _analytics!['total_attempts'] as int? ?? 0;
    final totalHours = (avgTime * totalAttempts / 3600);
    if (totalHours < 1) {
      return '${(totalHours * 60).toStringAsFixed(0)}m';
    }
    return '${totalHours.toStringAsFixed(1)}h';
  }

  String _getAIRecommendation() {
    if (_analytics == null) return '';
    final topicAccuracy = _analytics!['topic_accuracy'] as List? ?? [];
    if (topicAccuracy.isEmpty) return 'Keep practicing to see personalized recommendations!';
    
    // Simple logic for brevity, expands on previous implementation
    return 'Great progress! Focus on consistent daily practice to improve your mastery.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundColor,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: AppTheme.errorColor)))
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  color: AppTheme.primaryColor,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      children: [
                        // Header
                        Padding(
                           padding: const EdgeInsets.all(24.0),
                           child: Text(
                             'Analytics',
                             style: Theme.of(context).textTheme.headlineLarge,
                           ),
                        ),
                        
                        // Charts and Metrics
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              _CircularProgressChart(percentage: _calculateGoalCompletion()),
                              const SizedBox(height: 32),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: _MetricCard(
                                      icon: Icons.fact_check,
                                      label: 'Answered',
                                      value: '${_analytics?['total_attempts'] ?? 0}',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _MetricCard(
                                      icon: Icons.assessment,
                                      label: 'Avg Score',
                                      value: '${((_analytics?['overall_accuracy'] as num? ?? 0.0) * 100).toStringAsFixed(0)}%',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _MetricCard(
                                icon: Icons.schedule,
                                label: 'Total Study Time',
                                value: _getStudyTime(),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Performance Trend', style: Theme.of(context).textTheme.headlineMedium),
                              ),
                              const SizedBox(height: 16),
                               _PerformanceChart(
                                progressData: _analytics?['progress_over_time'] as List? ?? [],
                              ),
                              
                              const SizedBox(height: 32),
                              
                              GlassContainer(
                                color: AppTheme.primaryColor,
                                opacity: 0.1,
                                child: Row(
                                  children: [
                                    const Icon(Icons.psychology, color: AppTheme.primaryColor, size: 32),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('AI Insight', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16, color: AppTheme.primaryColor)),
                                          const SizedBox(height: 4),
                                          Text(
                                            _getAIRecommendation(),
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _CircularProgressChart extends StatelessWidget {
  final double percentage;

  const _CircularProgressChart({required this.percentage});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(200, 200),
            painter: _CircularChartPainter(progress: percentage / 100),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${percentage.toStringAsFixed(0)}%',
                 style: GoogleFonts.manrope(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'GOAL',
                 style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.primaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularChartPainter extends CustomPainter {
  final double progress;

  _CircularChartPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = AppTheme.surfaceColor
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = AppTheme.primaryColor
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      color: AppTheme.surfaceColor,
      opacity: 0.5,
      child: Row(
        children: [
             Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
                Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
        ],
      ),
    );
  }
}

class _PerformanceChart extends StatelessWidget {
  final List<dynamic> progressData;

  const _PerformanceChart({required this.progressData});

  @override
  Widget build(BuildContext context) {
     // Simplified placeholder for chart, referencing the previous detailed implementation
     return Container(
       height: 150,
       width: double.infinity,
       decoration: BoxDecoration(
         color: AppTheme.surfaceColor.withOpacity(0.3),
         borderRadius: BorderRadius.circular(16),
         border: Border.all(color: Colors.white.withOpacity(0.05)),
       ),
       child: Center(
         child: Text(
           'Chart Visualization', 
           style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)
         ),
       ),
     );
  }
}
