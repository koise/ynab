import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import '../../services/auth_service.dart';
import '../../services/data_store.dart';
import '../../services/secure_storage_service.dart';
import '../../components/app_colors.dart';

class LockView extends StatefulWidget {
  final ValueChanged<bool> onUnlocked;

  const LockView({
    Key? key,
    required this.onUnlocked,
  }) : super(key: key);

  @override
  State<LockView> createState() => _LockViewState();
}

class _LockViewState extends State<LockView> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  String _enteredPIN = '';
  String _errorMessage = '';
  int _wrongAttempts = 0;
  int _cooldownRemaining = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateWithBiometricsIfNeeded();
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _authenticateWithBiometricsIfNeeded() async {
    final dataStore = Provider.of<DataStore>(context, listen: false);
    if (dataStore.userSettings.isBiometricEnabled) {
      await _authenticateWithBiometrics();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        setState(() {
          _errorMessage = 'Biometrics not available.';
        });
        return;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Unlock YNAB',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        widget.onUnlocked(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Biometric authentication failed.';
      });
    }
  }

  String _hashPIN(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _verifyPIN() async {
    final hashedInput = _hashPIN(_enteredPIN);
    final storedHash = await SecureStorageService.loadPIN();

    if (storedHash != null && hashedInput == storedHash) {
      widget.onUnlocked(true);
      setState(() {
        _wrongAttempts = 0;
      });
    } else {
      setState(() {
        _enteredPIN = '';
        _wrongAttempts++;
      });

      if (_wrongAttempts >= 10) {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.signOut();
      } else if (_wrongAttempts >= 3) {
        _startCooldown();
      } else {
        setState(() {
          _errorMessage = 'Incorrect PIN. ${10 - _wrongAttempts} attempts remaining.';
        });
      }
    }
  }

  void _startCooldown() {
    setState(() {
      _cooldownRemaining = 30;
      _errorMessage = 'Too many failed attempts.';
    });

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownRemaining > 0) {
        setState(() {
          _cooldownRemaining--;
        });
      } else {
        _cooldownTimer?.cancel();
        setState(() {
          _errorMessage = '';
          _wrongAttempts = 0;
        });
      }
    });
  }

  void _appendDigit(String digit) {
    if (_cooldownRemaining > 0 || _enteredPIN.length >= 6) return;
    setState(() {
      _enteredPIN += digit;
    });

    if (_enteredPIN.length == 6) {
      _verifyPIN();
    }
  }

  void _deleteDigit() {
    if (_cooldownRemaining > 0 || _enteredPIN.isEmpty) return;
    setState(() {
      _enteredPIN = _enteredPIN.substring(0, _enteredPIN.length - 1);
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataStore = Provider.of<DataStore>(context);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.systemBackground(context),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 50),
            Icon(
              CupertinoIcons.lock_fill,
              size: 50,
              color: CupertinoTheme.of(context).primaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              'Enter PIN',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.label(context),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final bool filled = index < _enteredPIN.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? AppColors.label(context)
                        : AppColors.secondaryLabel(context).withOpacity(0.3),
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),
            if (_cooldownRemaining > 0)
              Text(
                'Try again in $_cooldownRemaining seconds',
                style: const TextStyle(
                  color: CupertinoColors.systemRed,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              )
            else if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(
                  color: CupertinoColors.systemRed,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              const SizedBox(height: 14),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['1', '2', '3'].map((n) => _buildKey(n)).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['4', '5', '6'].map((n) => _buildKey(n)).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['7', '8', '9'].map((n) => _buildKey(n)).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      dataStore.userSettings.isBiometricEnabled
                          ? _buildBiometricKey()
                          : const SizedBox(width: 70, height: 70),
                      _buildKey('0'),
                      _buildDeleteKey(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String label) {
    return GestureDetector(
      onTap: _cooldownRemaining > 0 ? null : () => _appendDigit(label),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: CupertinoColors.secondaryLabel.resolveFrom(context).withOpacity(0.12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 28,
            color: AppColors.label(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricKey() {
    return GestureDetector(
      onTap: _cooldownRemaining > 0 ? null : _authenticateWithBiometrics,
      child: SizedBox(
        width: 70,
        height: 70,
        child: Icon(
          CupertinoIcons.shield,
          size: 32,
          color: AppColors.label(context),
        ),
      ),
    );
  }

  Widget _buildDeleteKey() {
    return GestureDetector(
      onTap: _cooldownRemaining > 0 || _enteredPIN.isEmpty ? null : _deleteDigit,
      child: SizedBox(
        width: 70,
        height: 70,
        child: Icon(
          CupertinoIcons.delete_left_fill,
          size: 28,
          color: AppColors.label(context),
        ),
      ),
    );
  }
}
