import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/features/auth/data/crypto_auth_service.dart';
import 'package:cryptolens_flutter/features/market/data/market_api.dart';
import 'package:cryptolens_flutter/features/watchlist/data/watchlist_store.dart';
import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/features/auth/presentation/login_screen.dart';
import 'package:cryptolens_flutter/features/auth/presentation/register_screen.dart';
import 'package:cryptolens_flutter/features/auth/presentation/splash_screen.dart';
import 'package:cryptolens_flutter/features/market/presentation/market_controller.dart';
import 'package:cryptolens_flutter/app/app_shell.dart';

class CryptoLensApp extends StatefulWidget {
  const CryptoLensApp({super.key});

  @override
  State<CryptoLensApp> createState() => _CryptoLensAppState();
}

class _CryptoLensAppState extends State<CryptoLensApp> {
  final _authService = CryptoAuthService();
  late final MarketController marketController;
  _AuthStage _stage = _AuthStage.splash;
  CryptoAuthUser? _user;
  LoginPreferences _loginPreferences = const LoginPreferences(
    rememberLogin: false,
    rememberedEmail: '',
  );
  StreamSubscription<CryptoAuthUser?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    marketController = MarketController(
      api: MarketApi(),
      watchlistStore: WatchlistStore(),
    )..initialize();
    _restoreSession();
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (!mounted || user == null) return;
      setState(() {
        _user = user;
        _stage = _AuthStage.home;
      });
    });
  }

  @override
  void dispose() {
    marketController.dispose();
    unawaited(_authSubscription?.cancel());
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
                _user = const CryptoAuthUser(
                  id: 'demo',
                  displayName: 'CryptoLens User',
                  email: 'demo@cryptolens.local',
                );
                _stage = _AuthStage.home;
              }),
            ),
            _AuthStage.login => LoginScreen(
              initialEmail: _loginPreferences.rememberedEmail,
              initialRemember: _loginPreferences.rememberLogin,
              onLogin: _login,
              onForgotPassword: _resetPassword,
              onRegister: () => setState(() => _stage = _AuthStage.register),
            ),
            _AuthStage.register => RegisterScreen(
              onBack: () => setState(() => _stage = _AuthStage.login),
              onRegister: _register,
            ),
            _AuthStage.home => AppShell(
              controller: marketController,
              displayName: _user?.displayName ?? 'CryptoLens User',
              email: _user?.email ?? '',
              onLogout: () async {
                await _authService.logout();
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
    final preferences = await _authService.loadLoginPreferences();
    final user = _authService.currentUser;
    if (!mounted) return;
    setState(() {
      _loginPreferences = preferences;
      if (user != null) {
        _user = user;
        _stage = _AuthStage.home;
      }
    });
  }

  Future<String?> _login(String email, String password, bool remember) async {
    try {
      final user = await _authService.login(
        email: email,
        password: password,
        remember: remember,
      );
      if (mounted) {
        setState(() {
          _user = user;
          _loginPreferences = LoginPreferences(
            rememberLogin: remember,
            rememberedEmail: remember ? email.trim() : '',
          );
          _stage = _AuthStage.home;
        });
      }
      return null;
    } on CryptoAuthException catch (error) {
      return error.message;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> _register(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    try {
      final user = await _authService.register(
        displayName: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      if (mounted) {
        setState(() {
          _user = user;
          _stage = _AuthStage.home;
        });
      }
      return null;
    } on CryptoAuthException catch (error) {
      return error.message;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> _resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      return null;
    } on CryptoAuthException catch (error) {
      return error.message;
    } catch (error) {
      return error.toString();
    }
  }
}

enum _AuthStage { splash, login, register, home }
