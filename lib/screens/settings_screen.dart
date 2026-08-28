import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../providers/theme_provider.dart';
import '../services/user_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_dialogs.dart';
import '../widgets/custom_font.dart';
import 'auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final bool confirmed = await CustomDialogs.confirm(
      context,
      title: 'Sign out?',
      message: 'You will need to sign in again to see your newsfeed.',
      confirmLabel: 'Sign Out',
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (!confirmed || !context.mounted) return;
    await UserService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(kDefaultPadding),
        children: <Widget>[
          CustomFont(
            'Preferences',
            family: CustomFontFamily.primary,
            fontSize: 16,
          ),
          const SizedBox(height: kSmallPadding),
          Card(
            child: SwitchListTile(
              title: const Text('Dark Theme'),
              subtitle: const Text('Match the app to a darker newsfeed.'),
              secondary: Icon(
                themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
                color: theme.colorScheme.primary,
              ),
              value: themeProvider.isDark,
              onChanged: themeProvider.toggleTheme,
            ),
          ),
          const SizedBox(height: kDefaultPadding),
          CustomFont('About', family: CustomFontFamily.primary, fontSize: 16),
          const SizedBox(height: kSmallPadding),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(kSpace16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CustomFont(kAppFullTitle, fontWeight: FontWeight.w600),
                  const SizedBox(height: kSpace8),
                  CustomFont(
                    'A social media application built with Flutter, '
                    'Provider, and the DummyJSON API (users, posts, comments).',
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: kSpace8),
                  CustomFont(
                    'Version 1.0.0',
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: kSpace24),
          CustomButton(
            label: 'Sign Out',
            outlined: true,
            color: theme.colorScheme.error,
            icon: Icons.logout,
            onPressed: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
