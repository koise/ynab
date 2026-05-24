import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../components/app_colors.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({Key? key}) : super(key: key);

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters long.';
      });
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await authService.signUpWithEmail(email, password);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.systemBackground(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.systemBackground(context),
        middle: Text(
          'Create Account',
          style: TextStyle(color: AppColors.label(context)),
        ),
        border: null,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CupertinoTextField(
                controller: _emailController,
                placeholder: 'Email',
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableSuggestions: false,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondarySystemBackground(context),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _passwordController,
                placeholder: 'Password',
                obscureText: true,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondarySystemBackground(context),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _confirmPasswordController,
                placeholder: 'Confirm Password',
                obscureText: true,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondarySystemBackground(context),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: CupertinoColors.systemRed,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : const Text('Sign Up'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
