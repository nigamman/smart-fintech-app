import '../../domain/entities/dashboard_data.dart';

abstract class DashboardRepository {
  Future<DashboardData> getDashboardData();
}