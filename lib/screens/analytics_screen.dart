import 'package:alo_draft_app/blocs/analytics/analytics_bloc.dart';
import 'package:alo_draft_app/blocs/analytics/analytics_event.dart';
import 'package:alo_draft_app/blocs/analytics/analytics_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late AnalyticsBloc _analyticsBloc;

  @override
  void initState() {
    super.initState();
    _analyticsBloc = AnalyticsBloc();
    _analyticsBloc.add(AnalyticsDataLoaded());
  }

  @override
  void dispose() {
    _analyticsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _analyticsBloc,
      child: Scaffold(
        body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
          builder: (context, state) {
            if (state is AnalyticsLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (state is AnalyticsLoaded) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: state.data.length,
                  itemBuilder: (context, index) {
                    final item = state.data[index];
                    return Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.icon,
                              size: 40,
                              color: item.color,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.value,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }
            if (state is AnalyticsFailure) {
              return Center(
                child: Text('Error: ${state.error}'),
              );
            }
            return const Center(
              child: Text('No analytics data available'),
            );
          },
        ),
      ),
    );
  }
}
