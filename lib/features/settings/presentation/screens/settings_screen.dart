import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../home/presentation/screens/history_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('Theme', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          // ignore: deprecated_member_use
          RadioListTile<ThemeMode>(
            title: const Text('System Default'),
            value: ThemeMode.system,
            // ignore: deprecated_member_use
            groupValue: themeMode,
            // ignore: deprecated_member_use
            onChanged: (value) {
              if (value != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(value);
              }
            },
          ),
          // ignore: deprecated_member_use
          RadioListTile<ThemeMode>(
            title: const Text('Light Mode'),
            value: ThemeMode.light,
            // ignore: deprecated_member_use
            groupValue: themeMode,
            // ignore: deprecated_member_use
            onChanged: (value) {
              if (value != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(value);
              }
            },
          ),
          // ignore: deprecated_member_use
          RadioListTile<ThemeMode>(
            title: const Text('Dark Mode'),
            value: ThemeMode.dark,
            // ignore: deprecated_member_use
            groupValue: themeMode,
            // ignore: deprecated_member_use
            onChanged: (value) {
              if (value != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(value);
              }
            },
          ),

          const Divider(height: 32),
          Text('Activity', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Work History'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),

          const Divider(height: 32),
          Text('Account', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              ref.read(authViewModelProvider.notifier).logout();
              // After logout, it will automatically route back due to main.dart ProviderScope listening to authState
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }
}
