import 'package:alo_draft_app/blocs/setting/setting_event.dart';
import 'package:alo_draft_app/blocs/setting/setting_state.dart';
import 'package:alo_draft_app/models/setting_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<NotificationToggled>(_onNotificationToggled);
    on<DarkModeToggled>(_onDarkModeToggled);
  }

  void _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) async {
    emit(SettingsLoading());
    try {
      // Simulate loading settings
      await Future.delayed(const Duration(milliseconds: 500));

      final settingsItems = [
        SettingsItem(
          title: 'Profile',
          subtitle: 'Edit your personal information',
          icon: Icons.person,
        ),
        SettingsItem(
          title: 'Security',
          subtitle: 'Password and authentication',
          icon: Icons.security,
        ),
        SettingsItem(
          title: 'Privacy',
          subtitle: 'Data and privacy settings',
          icon: Icons.privacy_tip,
        ),
        SettingsItem(
          title: 'Language',
          subtitle: 'Choose your preferred language',
          icon: Icons.language,
        ),
        SettingsItem(
          title: 'Storage',
          subtitle: 'Manage app storage',
          icon: Icons.storage,
        ),
        SettingsItem(
          title: 'Help & Support',
          subtitle: 'Get help and contact support',
          icon: Icons.help,
        ),
        SettingsItem(
          title: 'About',
          subtitle: 'App version and information',
          icon: Icons.info,
        ),
      ];

      emit(SettingsLoaded(
        notificationsEnabled: true,
        darkModeEnabled: false,
        settingsItems: settingsItems,
      ));
    } catch (e) {
      emit(SettingsFailure(e.toString()));
    }
  }

  void _onNotificationToggled(
      NotificationToggled event, Emitter<SettingsState> emit) {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      emit(SettingsLoaded(
        notificationsEnabled: event.value,
        darkModeEnabled: currentState.darkModeEnabled,
        settingsItems: currentState.settingsItems,
      ));
    }
  }

  void _onDarkModeToggled(DarkModeToggled event, Emitter<SettingsState> emit) {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      emit(SettingsLoaded(
        notificationsEnabled: currentState.notificationsEnabled,
        darkModeEnabled: event.value,
        settingsItems: currentState.settingsItems,
      ));
    }
  }
}
