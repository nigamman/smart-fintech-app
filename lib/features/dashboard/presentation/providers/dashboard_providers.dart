import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/datasources/dashboard_remote_datasource_impl.dart';
import '../../data/repositories/dashboard_repositories.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_data.dart';

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>((ref) {
  return DashboardRemoteDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(
    remoteDataSource: ref.watch(dashboardRemoteDataSourceProvider),
  );
});

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  // Automatically re-fetch dashboard when authState changes (e.g. login/logout)
  ref.watch(authStateProvider);
  return ref.read(dashboardRepositoryProvider).getDashboardData();
});
