import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local_datasource.dart';
import '../../data/datasources/remote_datasource.dart';
import '../../data/repositories/work_session_repository_impl.dart';
import '../../domain/repositories/work_session_repository.dart';
import '../viewmodels/time_viewmodel.dart';

final localDataSourceProvider = Provider<ObjectBoxService>((ref) {
  return ObjectBoxService();
});

final remoteDataSourceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

final workSessionRepositoryProvider = Provider<WorkSessionRepository>((ref) {
  final local = ref.watch(localDataSourceProvider);
  final remote = ref.watch(remoteDataSourceProvider);
  return WorkSessionRepositoryImpl(local, remote);
});

final timeViewModelProvider = NotifierProvider<TimeViewModel, TimeState>(() {
  return TimeViewModel();
});
