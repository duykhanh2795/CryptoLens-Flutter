import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/widgets/app_state_views.dart';
import 'package:cryptolens_flutter/core/validation/validators.dart';
import 'package:cryptolens_flutter/features/auth/presentation/widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.onLogin,
    required this.onRegister,
    required this.onForgotPassword,
    this.initialEmail = '',
    this.initialRemember = false,
    super.key,
  });

  final Future<String?> Function(String email, String password, bool remember)
  onLogin;
  final VoidCallback onRegister;
  final Future<String?> Function(String email) onForgotPassword;
  final String initialEmail;
  final bool initialRemember;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final _email = TextEditingController(text: widget.initialEmail);
  final _password = TextEditingController();
  late bool _remember = widget.initialRemember;
  bool _visible = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 60),
            const Center(child: AuthLogo(size: 64, textSize: 22)),
            const SizedBox(height: 16),
            const Text(
              'Welcome back',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AuthColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Log in to your CryptoLens account',
              textAlign: TextAlign.center,
              style: TextStyle(color: AuthColors.textSecondary),
            ),
            const SizedBox(height: 40),
            AuthField(
              controller: _email,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            AuthField(
              controller: _password,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              obscureText: !_visible,
              suffix: IconButton(
                onPressed: () => setState(() => _visible = !_visible),
                icon: Icon(
                  _visible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AuthColors.textSecondary,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Color(0xFFFF7182))),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _remember,
                  activeColor: AuthColors.yellow,
                  checkColor: const Color(0xFF1A1400),
                  onChanged: (value) =>
                      setState(() => _remember = value ?? true),
                ),
                const Expanded(
                  child: Text(
                    'Remember me',
                    style: TextStyle(color: AuthColors.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: _showForgotPassword,
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(color: AuthColors.yellow),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                style: authYellowButton(),
                child: _submitting
                    ? const AppInlineLoader(dimension: 18, strokeWidth: 2)
                    : const Text('Log In'),
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(child: Divider(color: AuthColors.surfaceVariant)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: TextStyle(color: AuthColors.textTertiary),
                  ),
                ),
                Expanded(child: Divider(color: AuthColors.surfaceVariant)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(color: AuthColors.textSecondary),
                ),
                TextButton(
                  onPressed: widget.onRegister,
                  child: const Text(
                    'Register Now',
                    style: TextStyle(color: AuthColors.yellow),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    final validationError =
        Validators.email(email) ??
        Validators.minLength(password, 6, 'Password');
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    final error = await widget.onLogin(email, password, _remember);
    if (!mounted) return;
    setState(() {
      _error = error;
      _submitting = false;
    });
  }

  void _showForgotPassword() {
    final input = TextEditingController(text: _email.text);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: input,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final email = input.text.trim();
              final error = await widget.onForgotPassword(email);
              if (!mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error ?? 'Reset email sent! Check your inbox.'),
                ),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
