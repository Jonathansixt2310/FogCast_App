import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/live_data_repository.dart';
import '../data/models/live_data_dto.dart';

class LiveDataState {
  final bool isLoading;
  final String? errorMessage;
  final LiveDataDto? data;

  const LiveDataState({
    this.isLoading = false,
    this.errorMessage,
    this.data,
  });

  LiveDataState copyWith({
    bool? isLoading,
    String? errorMessage,
    LiveDataDto? data,
  }) {
    return LiveDataState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      data: data ?? this.data,
    );
  }
}

class LiveDataNotifier extends StateNotifier<LiveDataState> {
  final LiveDataRepository _repository;

  LiveDataNotifier(this._repository) : super(const LiveDataState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _repository.getLiveData();
      state = LiveDataState(data: result, isLoading: false);
    } catch (e) {
      state = LiveDataState(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}