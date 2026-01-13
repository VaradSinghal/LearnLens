import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../core/user_service.dart';
import '../home_screen.dart';
import 'login_screen.dart';

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
  bool _isButtonPressed = false;
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  // Design colors matching the HTML
  static const Color primaryColor = Color(0xFF00AAFF);
  static const Color backgroundColor = Color(0xFF0A0A0A);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color slateSilver = Color(0xFFE0E0E0);
  static const Color mutedSilver = Color(0xFF9AB0BC);

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(() {
      setState(() {});
    });
    _emailFocusNode.addListener(() {
      setState(() {});
    });
    _passwordFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
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

      // Wait for user data to be fully initialized and reload user to avoid Pigeon errors
      if (userCredential.user != null) {
        // Update display name if provided
        if (_nameController.text.trim().isNotEmpty) {
          await userCredential.user!.updateDisplayName(_nameController.text.trim());
        }
        
        // Reload user to ensure all data is available
        await userCredential.user!.reload();
        final currentUser = FirebaseAuth.instance.currentUser;
        
        if (currentUser != null) {
          // Create user document in Firestore with name
          await UserService.createOrUpdateUserDocument(currentUser);
          
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
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
        // Extract meaningful error message
        String errorMessage = 'Registration failed. Please try again.';
        if (e.toString().contains('PigeonUserDetails') || 
            e.toString().contains('PlatformException')) {
          // If account was created but there's a Pigeon error, try to continue
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            try {
              await UserService.createOrUpdateUserDocument(currentUser);
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
                return;
              }
            } catch (_) {
              errorMessage = 'Account created but there was an issue. Please try signing in.';
            }
          } else {
            errorMessage = 'Account created but there was an issue loading user data. Please try signing in.';
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
      case 'email-already-in-use':
        return 'Email is already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return 'Registration failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Border around screen
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.03),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
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
                          const SizedBox(height: 8),
                          // Subtitle
                          Text(
                            'Join the Future of Learning',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: mutedSilver.withOpacity(0.6),
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),
                      // Form section
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 384),
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 16),
                              // Full Name Field
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                                    child: Text(
                                      'FULL NAME',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: mutedSilver.withOpacity(0.5),
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: _nameFocusNode.hasFocus
                                          ? [
                                              BoxShadow(
                                                color: primaryColor.withOpacity(0.1),
                                                blurRadius: 10,
                                                spreadRadius: 0,
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: TextFormField(
                                      controller: _nameController,
                                      focusNode: _nameFocusNode,
                                      style: GoogleFonts.manrope(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: slateSilver,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Enter your name',
                                        hintStyle: GoogleFonts.manrope(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          color: mutedSilver.withOpacity(0.3),
                                        ),
                                        filled: true,
                                        fillColor: deepCharcoal,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(0.1),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(0.1),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: primaryColor.withOpacity(0.5),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your name';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Email Field
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                                    child: Text(
                                      'EMAIL ADDRESS',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: mutedSilver.withOpacity(0.5),
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: _emailFocusNode.hasFocus
                                          ? [
                                              BoxShadow(
                                                color: primaryColor.withOpacity(0.1),
                                                blurRadius: 10,
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: slateSilver,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'email@example.com',
                                        hintStyle: GoogleFonts.manrope(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          color: mutedSilver.withOpacity(0.3),
                                        ),
                                        filled: true,
                                        fillColor: deepCharcoal,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(0.1),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(0.1),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: primaryColor.withOpacity(0.5),
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
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Password Field
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                                    child: Text(
                                      'CREATE PASSWORD',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: mutedSilver.withOpacity(0.5),
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: _passwordFocusNode.hasFocus
                                          ? [
                                              BoxShadow(
                                                color: primaryColor.withOpacity(0.1),
                                                blurRadius: 10,
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
                                        fontWeight: FontWeight.w400,
                                        color: slateSilver,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '••••••••',
                                        hintStyle: GoogleFonts.manrope(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          color: mutedSilver.withOpacity(0.3),
                                        ),
                                        filled: true,
                                        fillColor: deepCharcoal,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(0.1),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(0.1),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: primaryColor.withOpacity(0.5),
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
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Create Account Button
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
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: _isLoading ? null : _signUp,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        decoration: BoxDecoration(
                                          color: primaryColor,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryColor.withOpacity(0.3),
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
                                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A0A0A)),
                                                  ),
                                                )
                                              : Text(
                                                  'Create Account',
                                                  style: GoogleFonts.manrope(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: backgroundColor,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      // Bottom section with login link
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              color: mutedSilver.withOpacity(0.6),
                            ),
                            children: [
                              const TextSpan(text: 'Already have an account? '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          const begin = Offset(-1.0, 0.0);
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
                                    'Log In',
                                    style: GoogleFonts.manrope(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
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

