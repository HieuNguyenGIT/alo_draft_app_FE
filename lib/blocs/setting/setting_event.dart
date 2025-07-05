abstract class SettingEvent {}

class LoadSettings extends SettingEvent {}

class NotificationToggled extends SettingEvent {
  final bool enabled;
  NotificationToggled(this.enabled);
}

class DarkModeToggled extends SettingEvent {
  final bool enabled;
  DarkModeToggled(this.enabled);
}
