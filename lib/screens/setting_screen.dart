import 'package:alo_draft_app/blocs/auth/auth_bloc.dart';
import 'package:alo_draft_app/blocs/auth/auth_event.dart';
import 'package:alo_draft_app/blocs/auth/auth_state.dart';
import 'package:alo_draft_app/screens/socket_test_screen.dart';
import 'package:alo_draft_app/util/custom_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alo_draft_app/blocs/setting/setting_bloc.dart';
import 'package:alo_draft_app/blocs/setting/setting_event.dart';
import 'package:alo_draft_app/blocs/setting/setting_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsBloc _settingsBloc;

  @override
  void initState() {
    super.initState();
    _settingsBloc = SettingsBloc();
    _settingsBloc.add(LoadSettings());
  }

  @override
  void dispose() {
    _settingsBloc.close();
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                AppLogger.log("🚪 Logout button pressed");
                Navigator.of(dialogContext).pop();
                AppLogger.log("🔐 Triggering logout event");

                // 🔥 CRITICAL: Use the parent context (not dialog context)
                context.read<AuthBloc>().add(LoggedOut());
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _settingsBloc,
      child: Scaffold(
        body: BlocListener<AuthBloc, AuthState>(
          // 🔥 ADD: Listen to auth state changes in settings screen
          listener: (context, state) {
            AppLogger.log(
                "⚙️ Settings screen - Auth state changed: ${state.runtimeType}");

            if (state is AuthUnauthenticated) {
              AppLogger.log(
                  "🔄 User logged out, navigating to intro from settings");

              // Navigate and clear the entire stack
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/intro',
                (route) => false,
              );
            }
          },
          child: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              if (state is SettingsLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (state is SettingsLoaded) {
                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // User Profile Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: const Icon(
                                Icons.person,
                                size: 35,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'John Doe',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'john.doe@example.com',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Edit profile feature coming soon!')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Preferences Section
                    const Text(
                      'Preferences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Notifications'),
                            subtitle: const Text('Receive push notifications'),
                            secondary: const Icon(Icons.notifications),
                            value: state.notificationsEnabled,
                            onChanged: (value) {
                              context
                                  .read<SettingsBloc>()
                                  .add(NotificationToggled(value));
                            },
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: const Text('Dark Mode'),
                            subtitle: const Text('Use dark theme'),
                            secondary: const Icon(Icons.dark_mode),
                            value: state.darkModeEnabled,
                            onChanged: (value) {
                              context
                                  .read<SettingsBloc>()
                                  .add(DarkModeToggled(value));
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Settings Items
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Column(
                        children: state.settingsItems.map((item) {
                          final index = state.settingsItems.indexOf(item);
                          return Column(
                            children: [
                              ListTile(
                                leading: Icon(item.icon),
                                title: Text(item.title),
                                subtitle: Text(item.subtitle),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    size: 16),
                                onTap: item.onTap ??
                                    () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                '${item.title} feature coming soon!')),
                                      );
                                    },
                              ),
                              if (index < state.settingsItems.length - 1)
                                const Divider(height: 1),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Account Section
                    const Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.privacy_tip,
                                color: Colors.blue),
                            title: const Text('Privacy Policy'),
                            subtitle: const Text('View our privacy policy'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Privacy Policy feature coming soon!')),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.help_outline,
                                color: Colors.green),
                            title: const Text('Help & Support'),
                            subtitle:
                                const Text('Get help and contact support'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Help & Support feature coming soon!')),
                              );
                            },
                          ),
                          // Add this somewhere in your settings list
                          ListTile(
                            leading: const Icon(Icons.wifi, color: Colors.blue),
                            title: const Text('Socket.IO Test'),
                            subtitle: const Text('Test Socket.IO connection'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SocketIOTestScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.info_outline,
                                color: Colors.orange),
                            title: const Text('About'),
                            subtitle: const Text('App version and information'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('About'),
                                  content: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Alo Draft App'),
                                      Text('Version: 1.0.0'),
                                      Text('Build: 2024.01'),
                                      SizedBox(height: 10),
                                      Text(
                                          'A comprehensive business management app.'),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading:
                                const Icon(Icons.logout, color: Colors.red),
                            title: const Text(
                              'Logout',
                              style: TextStyle(color: Colors.red),
                            ),
                            subtitle: const Text('Sign out of your account'),
                            trailing: const Icon(Icons.arrow_forward_ios,
                                size: 16, color: Colors.red),
                            onTap: _showLogoutDialog,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              if (state is SettingsFailure) {
                return Center(
                  child: Text('Error: ${state.error}'),
                );
              }
              return const Center(
                child: Text('No settings available'),
              );
            },
          ),
        ),
      ),
    );
  }
}
