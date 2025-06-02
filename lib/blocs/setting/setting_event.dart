abstract class SettingsEvent {}

class LoadSettings extends SettingsEvent {}

class NotificationToggled extends SettingsEvent {
  final bool value;
  NotificationToggled(this.value);
}

class DarkModeToggled extends SettingsEvent {
  final bool value;
  DarkModeToggled(this.value);
}
