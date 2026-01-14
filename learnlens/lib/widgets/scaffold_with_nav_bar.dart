import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Crucial for glass effect over content
      body: Stack(
        children: [
          // Global Background Pattern (optional, matching login vibe)
          Positioned.fill(
            child: Container(
              color: AppTheme.backgroundColor,
            ),
          ),
           // Ambient background glow
          Positioned(
            top: -100,
            left: -100,
            child: ImageFiltered(
               imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
               child: Container(
                 width: 300,
                 height: 300,
                 decoration: BoxDecoration(
                   color: AppTheme.primaryColor.withOpacity(0.1),
                   shape: BoxShape.circle,
                 ),
               ),
            ),
          ),
          
          navigationShell,
        ],
      ),
      bottomNavigationBar: _CustomGlassNavBar(
        navigationShell: navigationShell,
      ),
      floatingActionButton: _LensFloatingActionButton(
        onPressed: () {
          // TODO: Trigger Document Upload/Scan
          // This should ideally show a modal bottom sheet or navigate to a dedicated scan screen
          // For now, we can show a snackbar or print a debug message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lens Scan/Upload Triggered!')),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _LensFloatingActionButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _LensFloatingActionButton({required this.onPressed});

  @override
  State<_LensFloatingActionButton> createState() => _LensFloatingActionButtonState();
}

class _LensFloatingActionButtonState extends State<_LensFloatingActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(seconds: 2), 
        vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        height: 72,
        width: 72,
        margin: const EdgeInsets.only(bottom: 20), // Lift it up slightly
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF00AAFF), Color(0xFF0066AA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00AAFF).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(36),
            child: const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomGlassNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _CustomGlassNavBar({required this.navigationShell});

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // A common pattern when switching branches, for example in bottom navigation bars, supports
      // initialLocation there need to be some logic to handle it.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90, // Taller to accommodate the FAB curve
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Glass Bar
          ClipRRect(
             borderRadius: const BorderRadius.only(
               topLeft: Radius.circular(30),
               topRight: Radius.circular(30),
             ),
             child: BackdropFilter(
               filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
               child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor.withOpacity(0.8),
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Left Side (Documents)
                      Expanded(
                        child: _NavBarItem(
                          icon: Icons.description_outlined,
                          activeIcon: Icons.description,
                          label: 'Documents',
                          isSelected: navigationShell.currentIndex == 0,
                          onTap: () => _goBranch(0),
                        ),
                      ),
                      
                      // Spacer for FAB
                      const SizedBox(width: 80),

                      // Right Side (Analytics & Profile) - Combining them or keeping 3 tabs?
                      // If we have 3 tabs (Documents, Analytics, Profile), and the FAB is separate action...
                      // The previous HomeScreen had 3 tabs. Let's keep 3 tabs but layout them around the FAB.
                      // Wait, with 3 tabs and a center FAB, usually one side has 2 and other has 1, or we treat FAB as the primary action and not a tab.
                      // Let's put Analytics in center? No, FAB is typically "Add".
                      // Let's split: Documents (Left), Analytics (Right), Profile (Far Right)?
                      // Or Documents (Left), FAB (Center), Analytics (Right), Profile (Far Right).
                      // That makes 3 items + FAB.
                      // Let's try: Documents (Left), Analytics (Middle Left?), NO.
                      // Standard 3 items with Center FAB usually means 2 items left, 2 items right, OR 
                      // 1 item left, 1 item right, and FAB is just floating.
                      // Let's do: Documents (Left), Analytics (Center-Left hidden by FAB? No), Profile (Right).
                      // The user said: "separate screens for uploaded documents, analytics and profile screen".
                      // So we have 3 screens.
                      // Layout: Documents (0) --- FAB --- Analytics (1) -- Profile (2)?
                      // Asymmetric.
                      // How about: Documents (0) -- Analytics (1) -- SPACE -- Profile (2)?
                      // Or just standard 3 buttons, ignoring the FAB "dock" for a moment and just let FAB float above?
                      // The user asked for "Centre UI button called lens".
                      // So Documents (Left), Profile (Right), and maybe Stats somewhere?
                      // Let's stick to 3 tabs for content.
                      // Maybe Documents (Left), Analytics (Right), and put Profile in the top app bar?
                      // Or Documents (Left), Analytics (Right), and Profile is a small icon?
                      // Re-reading user request: "screens for uploaded documents, analytics and profile screen".
                      // Let's do: Documents (Left) -- SPACER (FAB) -- Analytics (Right) -- Profile (Far Right).
                      // Wait, 1 left, 2 right is weird.
                      // Let's do 4 items? Home/Docs, Search/Explore?
                      // Let's look at the old HomeScreen. It had Docs, Analytics, Profile.
                      // Design choice: 
                      // 1. Documents
                      // 2. Analytics
                      // 3. Profile
                      // If I put FAB in middle, it splits them.
                      // Let's do: [Documents] [Analytics] -- FAB -- [Profile] [Settings?]
                      // Since we don't have a 4th tab, let's keep it balanced:
                      // [Documents] -- FAB -- [Analytics]
                      // And move Profile to the Top Right of the screen (App Bar).
                      // This is a common pattern when Profile is less accessed.
                      // However, user specifically listed "profile screen" as a main screen.
                      // Let's try to fit 3 in the bottom nav.
                      // [Docs] [Analytics] [Profile]
                      // With FAB floating above.
                      // Simple and clean.
                      
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                             _NavBarItem(
                              icon: Icons.insights_outlined,
                              activeIcon: Icons.insights,
                              label: 'Analytics',
                              isSelected: navigationShell.currentIndex == 1,
                              onTap: () => _goBranch(1),
                            ),
                             _NavBarItem(
                              icon: Icons.person_outline,
                              activeIcon: Icons.person,
                              label: 'Profile',
                              isSelected: navigationShell.currentIndex == 2,
                              onTap: () => _goBranch(2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
               ),
             ),
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Redesigning to be just an Icon with a glow if selected, or column with text
    // "Beautiful design" -> Minimalist.
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ) 
              ] : [],
            ),
            child: Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              size: 26,
            ),
          ),
          if (isSelected) ...[
             const SizedBox(height: 4),
             Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor, 
                ),
             )
          ]
        ],
      ),
    );
  }
}
