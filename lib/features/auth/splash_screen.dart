import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({
    required this.onContinue,
    required this.onDemo,
    super.key,
  });

  final VoidCallback onContinue;
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AuthColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
          child: Column(
            children: [
              const Spacer(),
              const _Logo(size: 82, textSize: 28),
              const SizedBox(height: 22),
              const Text(
                'CryptoLens',
                style: TextStyle(
                  color: _AuthColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track markets, portfolios, alerts, wallets and signals in one mobile app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _AuthColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: onContinue,
                  style: _yellowButton(),
                  child: const Text('Log In'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: onDemo,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _AuthColors.textPrimary,
                    side: const BorderSide(color: _AuthColors.surfaceVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Continue Demo'),
                ),
              ),
            ],
          ),
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
          color: Color(0xFF1A1400),
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
