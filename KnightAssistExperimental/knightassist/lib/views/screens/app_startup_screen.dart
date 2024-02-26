import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../providers/all_providers.dart';

import 'home_screen.dart';
import 'login_screen.dart';

class AppStartupScreen extends HookConsumerWidget {
  const AppStartupScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    return authState.maybeWhen(
      authenticated: (email) => const HomeScreen(),
      orElse: () => const LoginScreen(),
    );
  }
}
