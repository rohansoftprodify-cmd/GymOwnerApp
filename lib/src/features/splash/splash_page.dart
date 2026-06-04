import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_owner_app/src/core/navigation/post_auth_navigation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _handleStartUp();
  }

  Future<void> _handleStartUp() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      await navigateAfterSignIn(context, ref);
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onGradient = colorScheme.onPrimary;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: onGradient.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  size: 54,
                  color: onGradient,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'GYM OWNER',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: onGradient,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage • Track • Grow',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: onGradient.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: onGradient, strokeWidth: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
