import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/load.dart';
import '../services/load_service.dart';

// Load Service Provider
final loadServiceProvider = Provider<LoadService>((ref) => LoadService());

// Loads List Provider with filters
final loadsProvider = FutureProvider.family<List<Load>, LoadFilters>((ref, filters) async {
  final loadService = ref.watch(loadServiceProvider);
  return await loadService.getLoads(
    search: filters.search,
    status: filters.status,
    page: filters.page,
    limit: filters.limit,
  );
});

// Single Load Provider
final loadProvider = FutureProvider.family<Load, String>((ref, loadId) async {
  final loadService = ref.watch(loadServiceProvider);
  return await loadService.getLoad(loadId);
});

// Load Stats Provider
final loadStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final loadService = ref.watch(loadServiceProvider);
  return await loadService.getLoadStats();
});

// Load Filters State
class LoadFilters {
  final String? search;
  final LoadStatus? status;
  final int page;
  final int limit;

  const LoadFilters({
    this.search,
    this.status,
    this.page = 1,
    this.limit = 50,
  });

  LoadFilters copyWith({
    String? search,
    LoadStatus? status,
    int? page,
    int? limit,
  }) {
    return LoadFilters(
      search: search ?? this.search,
      status: status ?? this.status,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

// Load Filters State Notifier
class LoadFiltersNotifier extends Notifier<LoadFilters> {
  @override
  LoadFilters build() => const LoadFilters();

  void setSearch(String? search) {
    state = state.copyWith(search: search, page: 1);
  }

  void setStatus(LoadStatus? status) {
    state = state.copyWith(status: status, page: 1);
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
  }

  void reset() {
    state = const LoadFilters();
  }
}

final loadFiltersProvider = NotifierProvider<LoadFiltersNotifier, LoadFilters>(() {
  return LoadFiltersNotifier();
});

// Filtered Loads Provider
final filteredLoadsProvider = FutureProvider<List<Load>>((ref) async {
  final filters = ref.watch(loadFiltersProvider);
  return ref.watch(loadsProvider(filters).future);
});
