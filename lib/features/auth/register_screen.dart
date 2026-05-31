import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    required this.onBack,
    required this.onRegister,
    super.key,
  });

  final VoidCallback onBack;
  final void Function(String name, String email) onRegister;

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
      backgroundColor: _AuthColors.background,
      appBar: AppBar(
        backgroundColor: _AuthColors.background,
        foregroundColor: _AuthColors.textPrimary,
        title: const Text('Create Account'),
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          const Center(child: _Logo(size: 56, textSize: 18)),
          const SizedBox(height: 12),
          const Text(
            'Join CryptoLens',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _AuthColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Start your smart crypto journey',
            textAlign: TextAlign.center,
            style: TextStyle(color: _AuthColors.textSecondary),
          ),
          const SizedBox(height: 32),
          _AuthField(
            controller: _name,
            label: 'Full Name',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 14),
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
            _PasswordStrength(password: _password.text),
          const SizedBox(height: 14),
          _AuthField(
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
                color: _AuthColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _terms,
                    activeColor: _AuthColors.yellow,
                    checkColor: const Color(0xFF1A1400),
                    onChanged: (value) =>
                        setState(() => _terms = value ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      'I agree to the Terms of Service and Privacy Policy',
                      style: TextStyle(
                        color: _AuthColors.textSecondary,
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
              onPressed: _submit,
              style: _yellowButton(),
              child: const Text('Create Account'),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
                style: TextStyle(color: _AuthColors.textSecondary),
              ),
              TextButton(
                onPressed: widget.onBack,
                child: const Text(
                  'Log In',
                  style: TextStyle(color: _AuthColors.yellow),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    if (name.length < 2) {
      setState(() => _error = 'Enter your full name.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _error = 'Enter a valid email.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (password != _confirm.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (!_terms) {
      setState(() => _error = 'Accept the terms to continue.');
      return;
    }
    widget.onRegister(name, email);
  }
}

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = password.length >= 8 && password.contains(RegExp(r'[0-9]'))
        ? 3
        : password.length >= 6
        ? 2
        : 1;
    final color = strength >= 3
        ? const Color(0xFF00C087)
        : strength == 2
        ? _AuthColors.yellow
        : const Color(0xFFFF7182);
    final label = strength >= 3
        ? 'Good'
        : strength == 2
        ? 'Fair'
        : 'Weak';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: i < strength ? color : _AuthColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Password strength: $label',
              style: TextStyle(color: color, fontSize: 12),
            ),
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
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
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
  static const yellow = Color(0xFFF0B90B);
}
