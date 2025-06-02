import 'package:alo_draft_app/models/analytics_model.dart';

abstract class AnalyticsState {}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsLoaded extends AnalyticsState {
  final List<AnalyticsData> data;
  AnalyticsLoaded(this.data);
}

class AnalyticsFailure extends AnalyticsState {
  final String error;
  AnalyticsFailure(this.error);
}
