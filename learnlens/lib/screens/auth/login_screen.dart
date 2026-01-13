import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../core/user_service.dart';
import '../home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isButtonPressed = false;
  bool _isForgotPasswordHovered = false;
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  // Design colors matching the HTML
  static const Color primaryColor = Color(0xFF00AAFF);
  static const Color backgroundColor = Color(0xFF0A0A0A);
  static const Color mutedSilver = Color(0xFF9AB0BC);

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      setState(() {});
    });
    _passwordFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Ensure user document exists in Firestore (create if missing)
      if (userCredential.user != null) {
        // Reload user to ensure all data is available
        await userCredential.user!.reload();
        final currentUser = FirebaseAuth.instance.currentUser;
        
        if (currentUser != null) {
          // Ensure user document exists (creates if missing, updates if exists)
          await UserService.ensureUserDocumentExists(currentUser);
        }
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
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
        String errorMessage = 'Authentication failed. Please try again.';
        if (e.toString().contains('PigeonUserDetails') || 
            e.toString().contains('PlatformException')) {
          // If there's a Pigeon error but user is logged in, try to continue
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            try {
              await UserService.ensureUserDocumentExists(currentUser);
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
                return;
              }
            } catch (_) {
              errorMessage = 'Signed in but there was an issue. Please try again.';
            }
          }
        } else if (e.toString().isNotEmpty) {
          errorMessage = 'Error: ${e.toString().split('\n').first}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Background blur effect
            Positioned(
              top: MediaQuery.of(context).size.height / 2,
              left: MediaQuery.of(context).size.width / 2,
              child: Transform.translate(
                offset: const Offset(-250, -250),
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Main content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top section with title
                      Column(
                        children: [
                          const SizedBox(height: 60),
                          // Title
                          Text(
                            'LearnLens',
                            style: GoogleFonts.manrope(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 80),
                      // Form section
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 384),
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                            const SizedBox(height: 32),
                            // Email Field
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _emailFocusNode.hasFocus
                                    ? [
                                        BoxShadow(
                                          color: primaryColor.withOpacity(0.2),
                                          blurRadius: 8,
                                          spreadRadius: 0,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: TextFormField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                keyboardType: TextInputType.emailAddress,
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                                decoration: InputDecoration(
                                    hintText: 'Email Address',
                                    hintStyle: GoogleFonts.manrope(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w300,
                                      color: mutedSilver.withOpacity(0.4),
                                      letterSpacing: 0.5,
                                    ),
                                  filled: false,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: primaryColor,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Password Field
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _passwordFocusNode.hasFocus
                                    ? [
                                        BoxShadow(
                                          color: primaryColor.withOpacity(0.2),
                                          blurRadius: 8,
                                          spreadRadius: 0,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                focusNode: _passwordFocusNode,
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                                decoration: InputDecoration(
                                      hintText: 'Password',
                                      hintStyle: GoogleFonts.manrope(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w300,
                                        color: mutedSilver.withOpacity(0.4),
                                        letterSpacing: 0.5,
                                      ),
                                  filled: false,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: primaryColor,
                                      width: 1,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: mutedSilver.withOpacity(0.6),
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() => _obscurePassword = !_obscurePassword);
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Sign In Button
                            GestureDetector(
                              onTapDown: (_) {
                                if (!_isLoading) {
                                  setState(() => _isButtonPressed = true);
                                }
                              },
                              onTapUp: (_) {
                                if (!_isLoading) {
                                  setState(() => _isButtonPressed = false);
                                }
                              },
                              onTapCancel: () {
                                if (!_isLoading) {
                                  setState(() => _isButtonPressed = false);
                                }
                              },
                              child: AnimatedScale(
                                scale: _isButtonPressed ? 0.98 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: Material(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    onTap: _isLoading ? null : _signIn,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryColor.withOpacity(0.4),
                                            blurRadius: 15,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                              : Text(
                                                  'Sign In',
                                                  style: GoogleFonts.manrope(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Forgot Password Link
                            Center(
                              child: MouseRegion(
                                onEnter: (_) => setState(() => _isForgotPasswordHovered = true),
                                onExit: (_) => setState(() => _isForgotPasswordHovered = false),
                                child: TextButton(
                                  onPressed: () {
                                    // TODO: Implement forgot password functionality
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      color: _isForgotPasswordHovered
                                          ? primaryColor
                                          : mutedSilver.withOpacity(0.6),
                                    ),
                                    child: const Text('Forgot Password?'),
                                  ),
                                ),
                              ),
                            ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                      // Bottom section with sign up link
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              color: mutedSilver.withOpacity(0.6),
                            ),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) => const SignUpScreen(),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          const begin = Offset(1.0, 0.0);
                                          const end = Offset.zero;
                                          const curve = Curves.easeInOut;

                                          var tween = Tween(begin: begin, end: end).chain(
                                            CurveTween(curve: curve),
                                          );

                                          return SlideTransition(
                                            position: animation.drive(tween),
                                            child: child,
                                          );
                                        },
                                        transitionDuration: const Duration(milliseconds: 300),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Create one',
                                    style: GoogleFonts.manrope(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: primaryColor,
                                      decoration: TextDecoration.underline,
                                      decorationColor: primaryColor,
                                    ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}


