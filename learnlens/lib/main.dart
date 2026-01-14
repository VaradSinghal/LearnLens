import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'bloc/document/document_bloc.dart';
import 'bloc/question/question_bloc.dart';
import 'core/user_service.dart';
import 'core/router.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

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
      child: MaterialApp.router(
        title: 'Learn Lens',
        theme: AppTheme.darkTheme, // Using our new Unified Dark Theme
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
  }
}
