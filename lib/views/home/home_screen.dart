// lib/views/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/views/widgets/app_drawer.dart';
import 'package:resto2/views/widgets/loading_indicator.dart';
import 'package:resto2/views/widgets/notification_bell.dart';
import '../../providers/auth_providers.dart';
import '../../utils/constants.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(UIStrings.home),
        actions: const [NotificationBell()],
      ),
      drawer: const AppDrawer(), // Add the drawer here
      body: SafeArea(
        child: currentUser.when(
          data: (appUser) {
            if (appUser == null || appUser.role == null) {
              return const LoadingIndicator();
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    UIStrings.welcomeMessage.replaceFirst(
                      '{name}',
                      appUser.displayName ?? UIStrings.defaultUserName,
                    ),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    UIStrings.yourRole.replaceFirst(
                      '{role}',
                      appUser.role!.name,
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const LoadingIndicator(),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
