import '../../domain/entities/dashboard_data.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardData> getDashboardData();
}