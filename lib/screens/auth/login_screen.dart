import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/constants.dart';
import '../../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    // Clear previous field errors
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (!mounted) return;

    if (result['success']) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      final msg = (result['message'] ?? '').toString();

      // map server errors to field errors when possible
      if (msg.contains('Email belum terdaftar') ||
          msg.contains('Format email')) {
        setState(() => _emailError = msg);
      } else if (msg.contains('Password salah')) {
        setState(() => _passwordError = msg);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                const SizedBox(height: AppSpacing.xxl),
                const Text(
                  'Selamat Datang!',
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.sm),

                const Text(
                  'Masuk untuk melanjutkan ke ${AppConstants.appName}',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xl),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Masukkan email Anda',
                    prefixIcon: Icon(Icons.email_outlined),
                    // errorText will be provided dynamically
                  ).copyWith(errorText: _emailError),
                  validator: AppValidators.email,
                  onChanged: (v) {
                    if (_emailError != null) setState(() => _emailError = null);
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Masukkan password Anda',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    // show password related errors from server
                  ).copyWith(errorText: _passwordError),
                  validator: AppValidators.password,
                  onChanged: (v) {
                    if (_passwordError != null) setState(() => _passwordError = null);
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Masuk'),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text(
                        'ATAU',
                        style: AppTextStyles.caption,
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/register');
                  },
                  child: const Text('Daftar Akun Baru'),
                ),

                const SizedBox(height: AppSpacing.xl),
                const Text(
                  'Dengan masuk, Anda menyetujui Syarat & Ketentuan '
                  'dan Kebijakan Privasi kami',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
