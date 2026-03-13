import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Office Time Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authViewModelProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (authState.user?.photoUrl.isNotEmpty == true)
              CircleAvatar(
                backgroundImage: NetworkImage(authState.user!.photoUrl),
                radius: 40,
              ),
            const SizedBox(height: 16),
            Text(
              'Welcome, ${authState.user?.name ?? "User"}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Email: ${authState.user?.email ?? ""}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
