import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../components/app_colors.dart';

class LinkAccountSheet extends StatefulWidget {
  const LinkAccountSheet({Key? key}) : super(key: key);

  @override
  State<LinkAccountSheet> createState() => _LinkAccountSheetState();
}

class _LinkAccountSheetState extends State<LinkAccountSheet> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _linkAccount() async {
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
      await authService.linkEmail(email, password);
      setState(() {
        _isSuccess = true;
        _isLoading = false;
      });
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
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.systemBackground(context),
        middle: Text(
          'Link Email',
          style: TextStyle(color: AppColors.label(context)),
        ),
        leading: _isSuccess
            ? const SizedBox.shrink()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
        border: null,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _isSuccess ? _buildSuccessView() : _buildLinkForm(),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Icon(
            CupertinoIcons.check_mark_circled_solid,
            color: CupertinoColors.systemGreen,
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            'Account Linked Successfully!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.label(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Your data is now safely backed up to this email.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondaryLabel(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: CupertinoColors.activeBlue,
              borderRadius: BorderRadius.circular(12),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkForm() {
    return Column(
      children: [
        Text(
          'Secure your data by linking your guest account to an email address.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.secondaryLabel(context),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
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
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: CupertinoColors.activeBlue,
            borderRadius: BorderRadius.circular(12),
            onPressed: _isLoading ? null : _linkAccount,
            child: _isLoading
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : const Text('Link Account'),
          ),
        ),
      ],
    );
  }
}
