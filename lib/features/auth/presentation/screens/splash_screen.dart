import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/features/auth/presentation/widgets/auth_widgets.dart';

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
      backgroundColor: AuthColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
          child: Column(
            children: [
              const Spacer(),
              const AuthLogo(size: 82, textSize: 28),
              const SizedBox(height: 22),
              const Text(
                'CryptoLens',
                style: TextStyle(
                  color: AuthColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track markets, portfolios, alerts, wallets and signals in one mobile app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AuthColors.textSecondary,
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
                  style: authYellowButton(),
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
                    foregroundColor: AuthColors.textPrimary,
                    side: const BorderSide(color: AuthColors.surfaceVariant),
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
