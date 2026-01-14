import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../core/user_service.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/custom_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        if (_nameController.text.trim().isNotEmpty) {
          await userCredential.user!.updateDisplayName(_nameController.text.trim());
        }
        
        await userCredential.user!.reload();
        if (FirebaseAuth.instance.currentUser != null) {
          await UserService.createOrUpdateUserDocument(FirebaseAuth.instance.currentUser!);
          if (mounted) context.go('/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e.code)),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Extract message from Exception if possible
        final message = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $message'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Email is already registered.';
      case 'weak-password': return 'Password is too weak.';
      case 'invalid-email': return 'Invalid email address.';
      default: return 'Registration failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          image: DecorationImage(
            image: NetworkImage('https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=2072&auto=format&fit=crop'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: Stack(
          children: [
            // Background Gradient Blob
            Positioned(
              bottom: -100,
              left: -100,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Join LearnLens',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start your learning journey today',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 48),

                    GlassContainer(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              hint: 'Enter your name',
                              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                            ),
                            const SizedBox(height: 24),
                            
                            CustomTextField(
                              controller: _emailController,
                              label: 'Email',
                              hint: 'Enter your email',
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                            ),
                            const SizedBox(height: 24),
                            
                            CustomTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: 'Create a password',
                              obscureText: _obscurePassword,
                              validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 chars' : null,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: AppTheme.textSecondary,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            ElevatedButton(
                              onPressed: _isLoading ? null : _signUp,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: AppTheme.primaryColor,
                                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 16),
                              ),
                              child: _isLoading 
                                ? const SizedBox(
                                    height: 20, width: 20, 
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  )
                                : const Text('Create Account'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: RichText(
                        text: TextSpan(
                          text: "Already have an account? ",
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: [
                            TextSpan(
                              text: 'Log In',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
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
