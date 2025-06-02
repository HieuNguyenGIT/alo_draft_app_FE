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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _settingsBloc,
      child: Scaffold(
        body: BlocBuilder<SettingsBloc, SettingsState>(
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
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: item.onTap ??
                                  () {
                                    ScaffoldMessenger.of(context).showSnackBar(
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
    );
  }
}
