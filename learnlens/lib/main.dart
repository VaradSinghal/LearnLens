import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'bloc/document/document_bloc.dart';
import 'bloc/question/question_bloc.dart';
import 'core/user_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => DocumentBloc()),
        BlocProvider(create: (context) => QuestionBloc()),
      ],
      child: MaterialApp(
        title: 'Learn Lens',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashWrapper(),
        routes: {
          '/signup': (context) => const SignUpScreen(),
        },
      ),
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _showSplash = true;

  void _onSplashComplete() {
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onComplete: _onSplashComplete);
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasData) {
          // Ensure user document exists when user is logged in
          final user = snapshot.data;
          if (user != null) {
            // Ensure user document exists (non-blocking)
            UserService.ensureUserDocumentExists(user).catchError((e) {
              print('Error ensuring user document on auth state change: $e');
            });
          }
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
