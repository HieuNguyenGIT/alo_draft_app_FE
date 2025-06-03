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

      // Calculate totals from the last 7 days mock data
      final data = [
        AnalyticsData(
          title: 'Tổng truy cập',
          value: '612',
          icon: Icons.visibility,
          color: Colors.orange,
        ),
        AnalyticsData(
          title: 'Liên hệ',
          value: '120',
          icon: Icons.contact_phone,
          color: Colors.blue,
        ),
        AnalyticsData(
          title: 'Popup đăng ký',
          value: '47',
          icon: Icons.people_outline,
          color: Colors.green,
        ),
        AnalyticsData(
          title: 'Người dùng mới',
          value: '89',
          icon: Icons.person_add,
          color: Colors.purple,
        ),
        AnalyticsData(
          title: 'Tỷ lệ chuyển đổi',
          value: '19.6%',
          icon: Icons.trending_up,
          color: Colors.teal,
        ),
        AnalyticsData(
          title: 'Thời gian trung bình',
          value: '2:34',
          icon: Icons.access_time,
          color: Colors.red,
        ),
      ];
      emit(AnalyticsLoaded(data));
    } catch (e) {
      emit(AnalyticsFailure(e.toString()));
    }
  }
}
