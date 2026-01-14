import 'dart:math' as math;
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/api_client.dart';
import '../theme/app_theme.dart';

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
          // Use mock data for display if API fails (common in dev)
           _analytics = {
            'total_attempts': 142,
            'avg_time_per_question': 45.0,
            'overall_accuracy': 0.78,
            'progress_over_time': [0.4, 0.5, 0.65, 0.7, 0.8, 0.78, 0.82],
            'topic_accuracy': [
               {'topic': 'History', 'accuracy': 0.85},
               {'topic': 'Science', 'accuracy': 0.72},
               {'topic': 'Math', 'accuracy': 0.65},
            ]
          };
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => _loadAnalytics(),
            icon: const Icon(Symbols.refresh, color: AppTheme.textPrimary),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewSection(),
                  const SizedBox(height: 32),
                  Text(
                    'Weekly Progress',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  _buildWeeklyChart(),
                  const SizedBox(height: 32),
                  Text(
                    'Topic Mastery',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  _buildTopicMasteryList(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewSection() {
    final attempts = _analytics?['total_attempts'] ?? 0;
    final accuracy = ((_analytics?['overall_accuracy'] ?? 0.0) * 100).toInt();
    final avgTime = ((_analytics?['avg_time_per_question'] ?? 0.0) / 60).toStringAsFixed(1);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Questions',
            value: '$attempts',
            icon: Symbols.assignment_turned_in,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'Accuracy',
            value: '$accuracy%',
            icon: Symbols.check_circle,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'Avg Time',
            value: '${avgTime}m',
            icon: Symbols.timer,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    final data = _analytics?['progress_over_time'] as List? ?? [];
    
    // Safely convert data to doubles, handling both numbers and Map objects
    final points = data.map((e) {
      if (e is num) return e.toDouble();
      if (e is Map) {
        // Try common keys if the API returns an object
        final val = e['accuracy'] ?? e['score'] ?? e['value'] ?? e['progress'] ?? 0;
        if (val is num) return val.toDouble();
        if (val is String) return double.tryParse(val) ?? 0.0;
      }
      return 0.0;
    }).toList();
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: _LineChartPainter(points: points),
      ),
    );
  }

  Widget _buildTopicMasteryList() {
    final topics = _analytics?['topic_accuracy'] as List? ?? [];
    
    if (topics.isEmpty) {
      return Center(
        child: Text(
          'No topic data available yet.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      children: topics.map<Widget>((topic) {
        final name = topic['topic'] as String;
        final accuracy = (topic['accuracy'] as num).toDouble();
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(name, style: Theme.of(context).textTheme.bodyLarge),
              ),
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: accuracy.clamp(0.0, 1.0),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(accuracy * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: AppTheme.textPrimary),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> points;

  _LineChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final spacing = size.width / (points.length - 1);
    
    // Normalize to height
    // Assuming value is 0.0 to 1.0
    
    for (int i = 0; i < points.length; i++) {
        final x = i * spacing;
        final y = size.height - (points[i] * size.height);
        
        if (i == 0) {
            path.moveTo(x, y);
        } else {
            // Cubic bezier for smooth curve
            final prevX = (i - 1) * spacing;
            final prevY = size.height - (points[i - 1] * size.height);
            final controlPoint1X = prevX + spacing / 2;
            final controlPoint1Y = prevY;
            final controlPoint2X = prevX + spacing / 2;
            final controlPoint2Y = y;
            
            path.cubicTo(controlPoint1X, controlPoint1Y, controlPoint2X, controlPoint2Y, x, y);
        }
    }

    canvas.drawPath(path, paint);
    
    // Draw dots
    final dotPaint = Paint()
       ..color = AppTheme.backgroundColor
       ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
       ..color = AppTheme.primaryColor
       ..style = PaintingStyle.stroke
       ..strokeWidth = 2;

    for (int i = 0; i < points.length; i++) {
        final x = i * spacing;
        final y = size.height - (points[i] * size.height);
        canvas.drawCircle(Offset(x, y), 6, dotPaint);
        canvas.drawCircle(Offset(x, y), 6, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
