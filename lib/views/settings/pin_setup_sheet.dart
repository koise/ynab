import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:crypto/crypto.dart';
import '../../services/data_store.dart';
import '../../services/secure_storage_service.dart';
import '../../components/app_colors.dart';

class PINSetupSheet extends StatefulWidget {
  const PINSetupSheet({Key? key}) : super(key: key);

  @override
  State<PINSetupSheet> createState() => _PINSetupSheetState();
}

class _PINSetupSheetState extends State<PINSetupSheet> {
  String _enteredPIN = '';
  String _confirmPIN = '';
  bool _isConfirming = false;
  String _errorMessage = '';

  String _hashPIN(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _verifyAndSave() async {
    if (_enteredPIN == _confirmPIN) {
      final hashed = _hashPIN(_enteredPIN);
      try {
        await SecureStorageService.savePIN(hashed);

        final dataStore = Provider.of<DataStore>(context, listen: false);
        final settings = dataStore.userSettings.copyWith(isPINEnabled: true);
        await dataStore.updateSettings(settings);

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to save PIN securely.';
          _enteredPIN = '';
          _confirmPIN = '';
          _isConfirming = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = 'PINs do not match. Try again.';
        _enteredPIN = '';
        _confirmPIN = '';
        _isConfirming = false;
      });
    }
  }

  void _appendDigit(String digit) {
    if (_isConfirming) {
      if (_confirmPIN.length < 6) {
        setState(() {
          _confirmPIN += digit;
        });
        if (_confirmPIN.length == 6) {
          _verifyAndSave();
        }
      }
    } else {
      if (_enteredPIN.length < 6) {
        setState(() {
          _enteredPIN += digit;
        });
        if (_enteredPIN.length == 6) {
          setState(() {
            _isConfirming = true;
          });
        }
      }
    }
  }

  void _deleteDigit() {
    if (_isConfirming) {
      if (_confirmPIN.isNotEmpty) {
        setState(() {
          _confirmPIN = _confirmPIN.substring(0, _confirmPIN.length - 1);
        });
      } else {
        setState(() {
          _isConfirming = false;
          _errorMessage = '';
        });
      }
    } else {
      if (_enteredPIN.isNotEmpty) {
        setState(() {
          _enteredPIN = _enteredPIN.substring(0, _enteredPIN.length - 1);
          _errorMessage = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentPIN = _isConfirming ? _confirmPIN : _enteredPIN;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.systemBackground(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.systemBackground(context),
        middle: Text(
          'Setup PIN',
          style: TextStyle(color: AppColors.label(context)),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Cancel'),
          onPressed: () {
            final dataStore = Provider.of<DataStore>(context, listen: false);
            final settings = dataStore.userSettings.copyWith(
              isPINEnabled: false,
              isBiometricEnabled: false,
            );
            dataStore.updateSettings(settings);
            Navigator.of(context).pop();
          },
        ),
        border: null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              _isConfirming ? 'Confirm your PIN' : 'Enter a 6-digit PIN',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.label(context),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final bool filled = index < currentPIN.length;
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
            const SizedBox(height: 24),
            if (_errorMessage.isNotEmpty)
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
                      const SizedBox(width: 70, height: 70),
                      _buildKey('0'),
                      _buildDeleteKey(currentPIN),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String label) {
    return GestureDetector(
      onTap: () => _appendDigit(label),
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

  Widget _buildDeleteKey(String currentPIN) {
    return GestureDetector(
      onTap: currentPIN.isEmpty ? null : _deleteDigit,
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
