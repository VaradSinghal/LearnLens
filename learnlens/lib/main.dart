import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'bloc/document/document_bloc.dart';
import 'bloc/question/question_bloc.dart';
import 'core/user_service.dart';
import 'theme/app_theme.dart';
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
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
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
        ),
        routes: {
          '/signup': (context) => const SignUpScreen(),
        },
      ),
    );
  }
}
