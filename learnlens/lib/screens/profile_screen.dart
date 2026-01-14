import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiClient _apiClient = ApiClient();
  Map<String, dynamic>? _analytics;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    try {
      final analytics = await _apiClient.getPerformanceAnalytics();
      if (mounted) setState(() => _analytics = analytics);
    } catch (_) {}
  }

  String _getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? 'Student';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundColor,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
               const SizedBox(height: 24),
               Container(
                 width: 100,
                 height: 100,
                 decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   color: AppTheme.surfaceColor,
                   border: Border.all(color: AppTheme.primaryColor, width: 2),
                   boxShadow: [
                     BoxShadow(
                       color: AppTheme.primaryColor.withOpacity(0.3),
                       blurRadius: 20,
                     ),
                   ],
                 ),
                 child: Icon(Icons.person, size: 50, color: AppTheme.textSecondary),
               ),
               const SizedBox(height: 16),
               Text(
                 _getUserName(),
                 style: Theme.of(context).textTheme.headlineMedium,
               ),
               Text(
                 'Learner Level ${_analytics != null ? ((_analytics!['total_attempts'] as int? ?? 0) / 10 + 1).floor() : 1}',
                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.primaryColor),
               ),
               
               const SizedBox(height: 48),
               
               _ProfileMenuItem(
                 icon: Icons.settings,
                 title: 'Settings',
                 onTap: () {},
               ),
               const SizedBox(height: 16),
               _ProfileMenuItem(
                 icon: Icons.notifications,
                 title: 'Notifications',
                 onTap: () {},
               ),
               const SizedBox(height: 16),
               _ProfileMenuItem(
                 icon: Icons.help_outline,
                 title: 'Help & Support',
                 onTap: () {},
               ),
               const SizedBox(height: 48),
               
               GlassContainer(
                 color: AppTheme.errorColor,
                 opacity: 0.1,
                 child: InkWell(
                   onTap: () async {
                     await FirebaseAuth.instance.signOut();
                     if (mounted) context.go('/login');
                   },
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const Icon(Icons.logout, color: AppTheme.errorColor),
                       const SizedBox(width: 8),
                       Text('Sign Out', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
                     ],
                   ),
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileMenuItem({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      color: AppTheme.surfaceColor,
      opacity: 0.5,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.bodyLarge)),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
