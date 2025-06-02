import 'package:alo_draft_app/models/setting_model.dart';

abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final List<SettingsItem> settingsItems;

  SettingsLoaded({
    required this.notificationsEnabled,
    required this.darkModeEnabled,
    required this.settingsItems,
  });
}

class SettingsFailure extends SettingsState {
  final String error;
  SettingsFailure(this.error);
}
