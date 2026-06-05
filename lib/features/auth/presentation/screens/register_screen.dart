import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/widgets/app_state_views.dart';
import 'package:cryptolens_flutter/core/validation/validators.dart';
import 'package:cryptolens_flutter/features/auth/presentation/widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    required this.onBack,
    required this.onRegister,
    super.key,
  });

  final VoidCallback onBack;
  final Future<String?> Function(
    String name,
    String email,
    String password,
    String confirmPassword,
  )
  onRegister;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _terms = false;
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.background,
      appBar: AppBar(
        backgroundColor: AuthColors.background,
        foregroundColor: AuthColors.textPrimary,
        title: const Text('Create Account'),
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          const Center(child: AuthLogo(size: 56, textSize: 18)),
          const SizedBox(height: 12),
          const Text(
            'Join CryptoLens',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AuthColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Start your smart crypto journey',
            textAlign: TextAlign.center,
            style: TextStyle(color: AuthColors.textSecondary),
          ),
          const SizedBox(height: 32),
          AuthField(
            controller: _name,
            label: 'Full Name',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 14),
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
            obscureText: !_passwordVisible,
            suffix: IconButton(
              onPressed: () =>
                  setState(() => _passwordVisible = !_passwordVisible),
              icon: Icon(
                _passwordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_password.text.isNotEmpty)
            PasswordStrength(password: _password.text),
          const SizedBox(height: 14),
          AuthField(
            controller: _confirm,
            label: 'Confirm Password',
            icon: Icons.lock_open_outlined,
            obscureText: !_confirmVisible,
            suffix: IconButton(
              onPressed: () =>
                  setState(() => _confirmVisible = !_confirmVisible),
              icon: Icon(
                _confirmVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () => setState(() => _terms = !_terms),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AuthColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _terms,
                    activeColor: AuthColors.yellow,
                    checkColor: const Color(0xFF1A1400),
                    onChanged: (value) =>
                        setState(() => _terms = value ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      'I agree to the Terms of Service and Privacy Policy',
                      style: TextStyle(
                        color: AuthColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Color(0xFFFF7182))),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: authYellowButton(),
              child: _submitting
                  ? const AppInlineLoader(dimension: 18, strokeWidth: 2)
                  : const Text('Create Account'),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
                style: TextStyle(color: AuthColors.textSecondary),
              ),
              TextButton(
                onPressed: widget.onBack,
                child: const Text(
                  'Log In',
                  style: TextStyle(color: AuthColors.yellow),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    final validationError =
        Validators.minLength(name, 2, 'Full name') ??
        Validators.email(email) ??
        Validators.minLength(password, 6, 'Password') ??
        Validators.matching(password, _confirm.text, 'Password') ??
        (!_terms ? 'Accept the terms to continue.' : null);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    final error = await widget.onRegister(name, email, password, _confirm.text);
    if (!mounted) return;
    setState(() {
      _error = error;
      _submitting = false;
    });
  }
}
