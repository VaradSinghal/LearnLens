import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  
  const SplashScreen({super.key, this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for the glow effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 0.7).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Progress animation from 0 to 100% over 4.5 seconds
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start progress animation
    _progressController.forward();
    
    // Call onComplete when animation finishes
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Colors from the HTML design
    const primaryBlue = Color(0xFF00AAFF);
    const backgroundDark = Color(0xFF1A1A1A);
    const backgroundLight = Color(0xFFF0F2F4);
    const slateSilver = Color(0xFFE0E0E0);
    const mutedSilver = Color(0xFF9AB0BC);

    return Scaffold(
      backgroundColor: backgroundDark,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  // Top spacer
                  const SizedBox(height: 48),
                  
                  // Central brand identity
                  Expanded(
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // AI-Blue Pulse Glow behind Logo
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 256,
                                height: 256,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      primaryBlue.withOpacity(
                                        0.2 * _pulseAnimation.value,
                                      ),
                                      primaryBlue.withOpacity(0),
                                    ],
                                    stops: const [0.0, 0.7],
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          // Logo and Text Column
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Logo Icon
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: slateSilver.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: backgroundDark.withOpacity(0.8),
                                ),
                                child: const Icon(
                                  Icons.lens_blur,
                                  color: slateSilver,
                                  size: 48,
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Typography Block
                              Column(
                                children: [
                                  // LearnLens Title
                                  Text(
                                    'LearnLens',
                                    style: GoogleFonts.manrope(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: -0.03 * 42,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Subtitle
                                  Text(
                                    'Intelligent Learning Systems',
                                    style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: primaryBlue,
                                      letterSpacing: 0.4 * 10,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Footer / Progress Area
                  SizedBox(
                    width: 280,
                    child: Column(
                      children: [
                        // System Status
                        Text(
                          'Calibrating Neural Engine',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: mutedSilver.withOpacity(0.6),
                            letterSpacing: 0.1 * 11,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Razor-thin Progress Bar
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return Stack(
                              children: [
                                // Background
                                Container(
                                  width: double.infinity,
                                  height: 1,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(0.5),
                                  ),
                                ),
                                // Progress fill (animated from 0 to 100%)
                                FractionallySizedBox(
                                  widthFactor: _progressAnimation.value,
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      color: primaryBlue,
                                      borderRadius: BorderRadius.circular(0.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryBlue.withOpacity(0.6),
                                          blurRadius: 8,
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // Secondary Metadata
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ver. 1.0.0',
                              style: GoogleFonts.manrope(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.7),
                                letterSpacing: 0.05 * 9,
                              ),
                            ),
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                final remainingTime = 
                                    (4.5 * (1 - _progressAnimation.value));
                                return Text(
                                  'EST: ${remainingTime.toStringAsFixed(1)}s',
                                  style: GoogleFonts.manrope(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.7),
                                    letterSpacing: 0.05 * 9,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
            
            // Decorative UI Element (Edge Frame)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withOpacity(0.03),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
