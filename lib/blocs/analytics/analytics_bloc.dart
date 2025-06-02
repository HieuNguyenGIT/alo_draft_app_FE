import 'package:alo_draft_app/blocs/analytics/analytics_event.dart';
import 'package:alo_draft_app/blocs/analytics/analytics_state.dart';
import 'package:alo_draft_app/models/analytics_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  AnalyticsBloc() : super(AnalyticsInitial()) {
    on<AnalyticsDataLoaded>(_onAnalyticsDataLoaded);
  }

  void _onAnalyticsDataLoaded(
      AnalyticsDataLoaded event, Emitter<AnalyticsState> emit) async {
    emit(AnalyticsLoading());
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      final data = [
        AnalyticsData(
          title: 'Total Tasks',
          value: '42',
          icon: Icons.task_alt,
          color: Colors.blue,
        ),
        AnalyticsData(
          title: 'Completed',
          value: '28',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        AnalyticsData(
          title: 'Pending',
          value: '14',
          icon: Icons.pending,
          color: Colors.orange,
        ),
        AnalyticsData(
          title: 'Contacts',
          value: '156',
          icon: Icons.people,
          color: Colors.purple,
        ),
        AnalyticsData(
          title: 'Messages',
          value: '89',
          icon: Icons.message,
          color: Colors.teal,
        ),
        AnalyticsData(
          title: 'This Week',
          value: '+12%',
          icon: Icons.trending_up,
          color: Colors.red,
        ),
      ];
      emit(AnalyticsLoaded(data));
    } catch (e) {
      emit(AnalyticsFailure(e.toString()));
    }
  }
}
