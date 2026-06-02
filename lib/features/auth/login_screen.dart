import 'package:flutter/material.dart';

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
      backgroundColor: _AuthColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 60),
            const Center(child: _Logo(size: 64, textSize: 22)),
            const SizedBox(height: 16),
            const Text(
              'Welcome back',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _AuthColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Log in to your CryptoLens account',
              textAlign: TextAlign.center,
              style: TextStyle(color: _AuthColors.textSecondary),
            ),
            const SizedBox(height: 40),
            _AuthField(
              controller: _email,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            _AuthField(
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
                  color: _AuthColors.textSecondary,
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
                  activeColor: _AuthColors.yellow,
                  checkColor: const Color(0xFF1A1400),
                  onChanged: (value) =>
                      setState(() => _remember = value ?? true),
                ),
                const Expanded(
                  child: Text(
                    'Remember me',
                    style: TextStyle(color: _AuthColors.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: _showForgotPassword,
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(color: _AuthColors.yellow),
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
                style: _yellowButton(),
                child: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Log In'),
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(child: Divider(color: _AuthColors.surfaceVariant)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: TextStyle(color: _AuthColors.textTertiary),
                  ),
                ),
                Expanded(child: Divider(color: _AuthColors.surfaceVariant)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(color: _AuthColors.textSecondary),
                ),
                TextButton(
                  onPressed: widget.onRegister,
                  child: const Text(
                    'Register Now',
                    style: TextStyle(color: _AuthColors.yellow),
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
    if (!email.contains('@')) {
      setState(() => _error = 'Enter a valid email.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
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

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: _AuthColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _AuthColors.textSecondary),
        suffixIcon: suffix,
        filled: true,
        fillColor: _AuthColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.size, required this.textSize});

  final double size;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: _AuthColors.yellow,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        'CL',
        style: TextStyle(
          color: const Color(0xFF1A1400),
          fontSize: textSize,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

ButtonStyle _yellowButton() {
  return FilledButton.styleFrom(
    backgroundColor: _AuthColors.yellow,
    foregroundColor: const Color(0xFF1A1400),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
  );
}

class _AuthColors {
  static const background = Color(0xFF050607);
  static const surfaceVariant = Color(0xFF1B1C1E);
  static const textPrimary = Color(0xFFF4F5F6);
  static const textSecondary = Color(0xFFA7ABB0);
  static const textTertiary = Color(0xFF6E737A);
  static const yellow = Color(0xFFF0B90B);
}
