import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'sign_up_view.dart';
import '../../components/app_colors.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _signInAnonymously() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await authService.signInAnonymously();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.systemBackground(context),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B6CF6), Color(0xFF9B59B6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B6CF6).withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'YNAB',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'You Need A Budget',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.label(context),
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Take control of your money',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.secondaryLabel(context),
                  ),
                ),
                const SizedBox(height: 40),

                // Email field
                _InputField(
                  controller: _emailController,
                  placeholder: 'Email address',
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  isDark: isDark,
                  prefixIcon: CupertinoIcons.mail,
                ),
                const SizedBox(height: 12),

                // Password field
                _InputField(
                  controller: _passwordController,
                  placeholder: 'Password',
                  obscureText: true,
                  isDark: isDark,
                  prefixIcon: CupertinoIcons.lock,
                ),

                // Error message
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: CupertinoColors.systemRed.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.exclamationmark_circle,
                          color: CupertinoColors.systemRed,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: CupertinoColors.systemRed,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Sign In button (gradient)
                _GradientButton(
                  label: 'Sign In',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _signIn,
                ),
                const SizedBox(height: 12),

                // Anonymous button (secondary)
                _SecondaryButton(
                  label: 'Try Anonymously',
                  isLoading: _isLoading,
                  isDark: isDark,
                  onPressed: _isLoading ? null : _signInAnonymously,
                ),
                const SizedBox(height: 32),

                // Sign Up link
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => const SignUpView(),
                      ),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(
                        color: AppColors.secondaryLabel(context),
                        fontSize: 14,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(
                            color: Color(0xFF5B6CF6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Reusable Input Field ──────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final bool obscureText;
  final bool autocorrect;
  final TextInputType? keyboardType;
  final bool isDark;
  final IconData prefixIcon;

  const _InputField({
    required this.controller,
    required this.placeholder,
    required this.isDark,
    required this.prefixIcon,
    this.obscureText = false,
    this.autocorrect = true,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
        ),
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        obscureText: obscureText,
        autocorrect: autocorrect,
        enableSuggestions: !obscureText,
        keyboardType: keyboardType,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: const BoxDecoration(),
        prefix: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Icon(
            prefixIcon,
            size: 18,
            color: CupertinoColors.systemGrey,
          ),
        ),
        style: TextStyle(
          color: isDark ? CupertinoColors.white : CupertinoColors.black,
          fontSize: 15,
        ),
        placeholderStyle: TextStyle(
          color: CupertinoColors.systemGrey,
          fontSize: 15,
        ),
      ),
    );
  }
}

// ─── Gradient Primary Button ───────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.label,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedOpacity(
        opacity: onPressed == null ? 0.55 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFF5B6CF6), Color(0xFF9B59B6)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B6CF6).withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
              : Text(
                  label,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Secondary Button ──────────────────────────────────────────────────────

class _SecondaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final bool isDark;
  final VoidCallback? onPressed;

  const _SecondaryButton({
    required this.label,
    required this.isLoading,
    required this.isDark,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedOpacity(
        opacity: onPressed == null ? 0.55 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
            border: Border.all(
              color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6),
            ),
          ),
          alignment: Alignment.center,
          child: isLoading
              ? CupertinoActivityIndicator(
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: isDark ? CupertinoColors.white : const Color(0xFF1C1C1E),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
