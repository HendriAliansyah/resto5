import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/user_settings_model.dart';
import 'package:resto2/providers/auth_providers.dart';

// New provider to hold the theme being previewed on the settings page.
// It is null when the user is not on the settings page.
final previewThemeModeProvider = StateProvider<ThemeMode?>((ref) => null);

final userSettingsProvider = StreamProvider.autoDispose<UserSettings>((ref) {
  final userAsyncValue = ref.watch(currentUserProvider);

  return userAsyncValue.when(
    data: (user) {
      if (user != null) {
        return ref.watch(firestoreServiceProvider).watchUserSettings(user.uid);
      }
      return Stream.value(UserSettings());
    },
    loading: () => Stream.value(UserSettings()),
    error: (err, stack) => Stream.value(UserSettings()),
  );
});

// This notifier now ONLY handles SAVING the theme to the database.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final userSettings = ref.watch(userSettingsProvider).asData?.value;
  return ThemeModeNotifier(ref, userSettings ?? UserSettings());
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Ref _ref;

  ThemeModeNotifier(this._ref, UserSettings settings) : super(settings.theme);

  Future<void> setThemeMode(ThemeMode themeMode) async {
    final user = _ref.read(currentUserProvider).asData?.value;
    if (user == null) return;

    // The state of this notifier will update automatically via the stream
    // once the database write is complete. We only need to write to the DB.
    try {
      await _ref
          .read(firestoreServiceProvider)
          .updateUserTheme(user.uid, themeMode.name);
    } catch (e) {
      debugPrint("Failed to save theme preference: $e");
    }
  }
}
