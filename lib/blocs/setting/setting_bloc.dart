import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:alo_draft_app/blocs/setting/setting_event.dart';
import 'package:alo_draft_app/blocs/setting/setting_state.dart';
import 'package:alo_draft_app/models/setting_model.dart';

class SettingsBloc extends Bloc<SettingEvent, SettingsState> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  SettingsBloc() : super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<NotificationToggled>(_onNotificationToggled);
    on<DarkModeToggled>(_onDarkModeToggled);
  }

  void _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) async {
    emit(SettingsLoading());
    try {
      // Simulate loading delay
      await Future.delayed(const Duration(milliseconds: 500));

      final settingsItems = [
        SettingsItem(
          title: 'Language',
          subtitle: 'English',
          icon: Icons.language,
        ),
        SettingsItem(
          title: 'Security',
          subtitle: 'Password and authentication',
          icon: Icons.security,
        ),
        SettingsItem(
          title: 'Data & Storage',
          subtitle: 'Manage your data and storage',
          icon: Icons.storage,
        ),
        SettingsItem(
          title: 'Backup',
          subtitle: 'Backup and restore settings',
          icon: Icons.backup,
        ),
      ];

      emit(SettingsLoaded(
        notificationsEnabled: _notificationsEnabled,
        darkModeEnabled: _darkModeEnabled,
        settingsItems: settingsItems,
      ));
    } catch (e) {
      emit(SettingsFailure(e.toString()));
    }
  }

  void _onNotificationToggled(
      NotificationToggled event, Emitter<SettingsState> emit) async {
    _notificationsEnabled = event.enabled;

    // Re-emit current state with updated notification setting
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      emit(SettingsLoaded(
        notificationsEnabled: _notificationsEnabled,
        darkModeEnabled: currentState.darkModeEnabled,
        settingsItems: currentState.settingsItems,
      ));
    }
  }

  void _onDarkModeToggled(
      DarkModeToggled event, Emitter<SettingsState> emit) async {
    _darkModeEnabled = event.enabled;

    // Re-emit current state with updated dark mode setting
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      emit(SettingsLoaded(
        notificationsEnabled: currentState.notificationsEnabled,
        darkModeEnabled: _darkModeEnabled,
        settingsItems: currentState.settingsItems,
      ));
    }
  }
}
