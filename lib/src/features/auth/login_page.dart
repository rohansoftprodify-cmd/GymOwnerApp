import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/auth/single_session_provider.dart';
import 'package:gym_owner_app/src/core/navigation/post_auth_navigation.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (Supabase.instance.client.auth.currentSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => navigateAfterSignIn(context, ref));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final sessionService = ref.read(singleSessionServiceProvider);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final hasActiveElsewhere = await sessionService.emailHasActiveSession(email);
      if (!mounted) return;

      if (hasActiveElsewhere) {
        setState(() => _loading = false);
        final proceed = await showConfirmDialog(
          context,
          title: 'Already signed in elsewhere',
          message:
              'This account is active on another device. '
              'Signing in here will log out that device.',
          confirmLabel: 'Continue',
          icon: Icons.devices_rounded,
        );
        if (!proceed || !mounted) return;
        setState(() {
          _loading = true;
          _error = null;
        });
      }

      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: _passwordController.text,
      );

      final hadOtherDevice = await sessionService.completeSignInAfterPassword();

      if (!mounted) return;

      if (hadOtherDevice) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(Icons.check_circle_outline_rounded),
            title: const Text('Signed in'),
            content: const Text(
              'You are signed in on this device. The other device has been logged out.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
        if (!mounted) return;
      }

      if (mounted) {
        await navigateAfterSignIn(context, ref);
      }
    } on AuthException catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, title: 'Sign in failed', error: e);
      }
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(
          context,
          title: 'Sign in failed',
          error: 'Unable to sign in. Please check your connection.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.4),
                  colorScheme.surface,
                  colorScheme.secondaryContainer.withOpacity(0.25),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppLogo(size: 72, borderRadius: 18),
                    const SizedBox(height: 16),
                    AppText(
                      'Welcome back',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      'Manage your gym efficiently',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    AppSurfaceCard(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppText(
                              'Login',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _emailController,
                              label: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              prefixIcon: const Icon(Icons.email_outlined, size: 18),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Enter email';
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Enter valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _passwordController,
                              label: 'Password',
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _signIn(),
                              prefixIcon: const Icon(Icons.lock_outline, size: 18),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Enter password';
                                if (value.length < 6) return 'Min 6 characters';
                                return null;
                              },
                            ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                  child: const Text('Forgot password?', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_error != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: colorScheme.errorContainer.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _error!,
                                    style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 11),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              AppPrimaryButton(
                                label: 'Sign In',
                                icon: Icons.login_rounded,
                                onPressed: _signIn,
                                isLoading: _loading,
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "No account?",
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Contact Admin',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ],
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
