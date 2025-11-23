import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/live_data_api.dart';
import '../data/live_data_repository.dart';
import 'live_data_notifier.dart';

// API-Client
final liveDataApiProvider = Provider<LiveDataApi>((ref) {
  return LiveDataApi();
});

// Repository
final liveDataRepositoryProvider = Provider<LiveDataRepository>((ref) {
  final api = ref.watch(liveDataApiProvider);
  return LiveDataRepository(api);
});

// StateNotifier + State
final liveDataNotifierProvider =
StateNotifierProvider<LiveDataNotifier, LiveDataState>((ref) {
  final repo = ref.watch(liveDataRepositoryProvider);
  return LiveDataNotifier(repo);
});