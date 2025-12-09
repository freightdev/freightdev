import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/driver.dart';
import '../services/driver_service.dart';

// Driver Service Provider
final driverServiceProvider = Provider<DriverService>((ref) => DriverService());

// Drivers List Provider with filters
final driversProvider = FutureProvider.family<List<Driver>, DriverFilters>((ref, filters) async {
  final driverService = ref.watch(driverServiceProvider);
  return await driverService.getDrivers(
    search: filters.search,
    status: filters.status,
    page: filters.page,
    limit: filters.limit,
  );
});

// Single Driver Provider
final driverProvider = FutureProvider.family<Driver, String>((ref, driverId) async {
  final driverService = ref.watch(driverServiceProvider);
  return await driverService.getDriver(driverId);
});

// Available Drivers Provider
final availableDriversProvider = FutureProvider<List<Driver>>((ref) async {
  final driverService = ref.watch(driverServiceProvider);
  return await driverService.getAvailableDrivers();
});

// Driver Stats Provider
final driverStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, driverId) async {
  final driverService = ref.watch(driverServiceProvider);
  return await driverService.getDriverStats(driverId);
});

// Driver Filters State
class DriverFilters {
  final String? search;
  final DriverStatus? status;
  final int page;
  final int limit;

  const DriverFilters({
    this.search,
    this.status,
    this.page = 1,
    this.limit = 50,
  });

  DriverFilters copyWith({
    String? search,
    DriverStatus? status,
    int? page,
    int? limit,
  }) {
    return DriverFilters(
      search: search ?? this.search,
      status: status ?? this.status,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

// Driver Filters State Notifier
class DriverFiltersNotifier extends Notifier<DriverFilters> {
  @override
  DriverFilters build() => const DriverFilters();

  void setSearch(String? search) {
    state = state.copyWith(search: search, page: 1);
  }

  void setStatus(DriverStatus? status) {
    state = state.copyWith(status: status, page: 1);
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
  }

  void reset() {
    state = const DriverFilters();
  }
}

final driverFiltersProvider = NotifierProvider<DriverFiltersNotifier, DriverFilters>(() {
  return DriverFiltersNotifier();
});

// Filtered Drivers Provider
final filteredDriversProvider = FutureProvider<List<Driver>>((ref) async {
  final filters = ref.watch(driverFiltersProvider);
  return ref.watch(driversProvider(filters).future);
});
