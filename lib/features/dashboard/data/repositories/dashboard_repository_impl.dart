import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../domain/entities/dashboard_data.dart';
import 'dashboard_repositories.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  const DashboardRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<DashboardData> getDashboardData() {
    return remoteDataSource.getDashboardData();
  }
}