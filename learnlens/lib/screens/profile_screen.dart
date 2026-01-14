import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/api_client.dart';
import '../theme/app_theme.dart';

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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Symbols.edit, color: AppTheme.textPrimary),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
             Center(
               child: Container(
                 width: 100,
                 height: 100,
                 decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   color: AppTheme.surfaceColor,
                   border: Border.all(color: AppTheme.border, width: 1),
                 ),
                 child: const Icon(Symbols.person, size: 50, color: AppTheme.textPrimary),
               ),
             ),
             const SizedBox(height: 16),
             Text(
               _getUserName(),
               style: Theme.of(context).textTheme.headlineMedium,
             ),
             Text(
               'Learner Level ${_analytics != null ? ((_analytics!['total_attempts'] as int? ?? 0) / 10 + 1).floor() : 1}',
               style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
             ),
             
             const SizedBox(height: 48),
             
             _ProfileMenuItem(
               icon: Icons.settings_outlined,
               title: 'Settings',
               onTap: () {},
             ),
             const SizedBox(height: 16),
             _ProfileMenuItem(
               icon: Icons.notifications_outlined,
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
             
             InkWell(
               onTap: () async {
                 await FirebaseAuth.instance.signOut();
                 if (mounted) context.go('/login');
               },
               borderRadius: BorderRadius.circular(12),
               child: Container(
                 padding: const EdgeInsets.symmetric(vertical: 16),
                 decoration: BoxDecoration(
                   border: Border.all(color: AppTheme.errorColor),
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const Icon(Icons.logout, color: AppTheme.errorColor),
                     const SizedBox(width: 8),
                     Text(
                       'Sign Out', 
                       style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                         color: AppTheme.errorColor, 
                         fontWeight: FontWeight.bold
                        )
                      ),
                   ],
                 ),
               ),
             ),
          ],
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.textPrimary),
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
        trailing: const Icon(Symbols.chevron_right, color: AppTheme.textSecondary),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
