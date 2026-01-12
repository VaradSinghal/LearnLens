import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String? assetPath;
  final IconData? icon;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.assetPath,
    this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (assetPath != null)
              SizedBox(
                width: 200,
                height: 200,
                child: Lottie.asset(assetPath!),
              )
            else if (icon != null)
              Icon(
                icon,
                size: 100,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

