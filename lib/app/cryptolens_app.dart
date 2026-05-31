import 'dart:async';

import 'package:flutter/material.dart';

import '../core/services/auth_session_store.dart';
import '../core/services/market_api.dart';
import '../core/services/watchlist_store.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/market/market_controller.dart';
import '../features/shell/app_shell.dart';

class CryptoLensApp extends StatefulWidget {
  const CryptoLensApp({super.key});

  @override
  State<CryptoLensApp> createState() => _CryptoLensAppState();
}

class _CryptoLensAppState extends State<CryptoLensApp> {
  final _authSessionStore = AuthSessionStore();
  late final MarketController marketController;
  _AuthStage _stage = _AuthStage.splash;
  _LocalUser? _user;

  @override
  void initState() {
    super.initState();
    marketController = MarketController(
      api: MarketApi(),
      watchlistStore: WatchlistStore(),
    )..initialize();
    _restoreSession();
  }

  @override
  void dispose() {
    marketController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CryptoLens',
      debugShowCheckedModeBanner: false,
      theme: CryptoLensTheme.lightTheme,
      home: AnimatedBuilder(
        animation: marketController,
        builder: (context, _) {
          return switch (_stage) {
            _AuthStage.splash => SplashScreen(
              onContinue: () => setState(() => _stage = _AuthStage.login),
              onDemo: () => setState(() {
                _user = const _LocalUser(
                  displayName: 'CryptoLens User',
                  email: 'demo@cryptolens.local',
                );
                _stage = _AuthStage.home;
              }),
            ),
            _AuthStage.login => LoginScreen(
              onLogin: (email, remember) {
                final user = _LocalUser(
                  displayName: email.split('@').first,
                  email: email,
                );
                if (remember) {
                  unawaited(
                    _authSessionStore.save(
                      StoredUser(
                        displayName: user.displayName,
                        email: user.email,
                      ),
                    ),
                  );
                }
                setState(() {
                  _user = user;
                  _stage = _AuthStage.home;
                });
              },
              onRegister: () => setState(() => _stage = _AuthStage.register),
            ),
            _AuthStage.register => RegisterScreen(
              onBack: () => setState(() => _stage = _AuthStage.login),
              onRegister: (name, email) {
                unawaited(
                  _authSessionStore.save(
                    StoredUser(displayName: name, email: email),
                  ),
                );
                setState(() {
                  _user = _LocalUser(displayName: name, email: email);
                  _stage = _AuthStage.home;
                });
              },
            ),
            _AuthStage.home => AppShell(
              controller: marketController,
              displayName: _user?.displayName ?? 'CryptoLens User',
              email: _user?.email ?? '',
              onLogout: () {
                unawaited(_authSessionStore.clear());
                setState(() {
                  _user = null;
                  _stage = _AuthStage.login;
                });
              },
            ),
          };
        },
      ),
    );
  }

  Future<void> _restoreSession() async {
    final stored = await _authSessionStore.load();
    if (!mounted || stored == null) return;
    setState(() {
      _user = _LocalUser(displayName: stored.displayName, email: stored.email);
      _stage = _AuthStage.home;
    });
  }
}

enum _AuthStage { splash, login, register, home }

class _LocalUser {
  const _LocalUser({required this.displayName, required this.email});

  final String displayName;
  final String email;
}
