import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/document_list_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/splash_screen.dart';
import '../widgets/scaffold_with_nav_bar.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashWrapper(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUpScreen(),
    ),
    
    // Stateful Shell Route for Tab Navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Documents
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home', // This will be the default home/documents
              builder: (context, state) => const DocumentListScreen(),
              routes: [
                 // Sub-routes for documents can go here
                 // GoRoute(path: 'details/:id', builder: ...)
              ],
            ),
          ],
        ),
        
        // Tab 1: Analytics
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
          ],
        ),
        
        // Tab 2: Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final isLoggingIn = state.uri.toString() == '/login';
    final isSigningUp = state.uri.toString() == '/signup';
    final isSplash = state.uri.toString() == '/';
    
    // Allow splash access always
    if (isSplash) return null;

    if (!isLoggedIn && !isLoggingIn && !isSigningUp) {
      return '/login';
    }

    if (isLoggedIn && (isLoggingIn || isSigningUp)) {
      return '/home';
    }

    return null;
  },
);

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Artificial delay for splash effect
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
