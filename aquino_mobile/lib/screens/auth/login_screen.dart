import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../services/user_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dialogs.dart';
import '../../widgets/custom_font.dart';
import '../../widgets/custom_text_formfield.dart';
import '../home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController(text: 'emilys');
  final TextEditingController _password = TextEditingController(
    text: 'emilyspass',
  );
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await UserService().loginUser(_username.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (_) {
      if (mounted) {
        CustomDialogs.showError(
          context,
          'Check your username and password, then try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(kSpace24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(kBorderRadius),
                      ),
                      child: Icon(
                        Icons.people,
                        size: 36,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: kSpace16),
                  Text(
                    kAppTitle,
                    textAlign: TextAlign.center,
                    style: textTheme.displayLarge,
                  ),
                  const SizedBox(height: kSpace8),
                  CustomFont(
                    'Sign in to continue',
                    textAlign: TextAlign.center,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: kSpace32),
                  CustomTextFormField(
                    controller: _username,
                    label: 'Username',
                    prefixIcon: Icons.person_outline,
                    validator: (String? value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Enter your username'
                        : null,
                  ),
                  const SizedBox(height: kSpace12),
                  CustomTextFormField(
                    controller: _password,
                    label: 'Password',
                    obscureText: _obscure,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (String? value) =>
                        (value == null || value.isEmpty)
                        ? 'Enter your password'
                        : null,
                  ),
                  const SizedBox(height: kSpace24),
                  CustomButton(
                    label: 'Sign In',
                    loading: _loading,
                    onPressed: _loading ? null : _signIn,
                  ),
                  const SizedBox(height: kSpace16),
                  CustomFont(
                    'Use the DummyJSON test account emilys / emilyspass, or any '
                    'username from dummyjson.com/users.',
                    textAlign: TextAlign.center,
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
