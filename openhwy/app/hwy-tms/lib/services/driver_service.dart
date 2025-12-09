import '../models/driver.dart';
import 'api_client.dart';

class DriverService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Driver>> getDrivers({
    String? search,
    DriverStatus? status,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null) 'status': status.name,
    };

    final response = await _apiClient.get('/drivers', queryParameters: queryParams);
    final data = response.data['data'] as List;
    return data.map((json) => Driver.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Driver> getDriver(String id) async {
    final response = await _apiClient.get('/drivers/$id');
    return Driver.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Driver> createDriver({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    String? cdlNumber,
    DateTime? cdlExpiry,
  }) async {
    final response = await _apiClient.post(
      '/drivers',
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        if (phone != null) 'phone': phone,
        if (cdlNumber != null) 'cdl_number': cdlNumber,
        if (cdlExpiry != null) 'cdl_expiry': cdlExpiry.toIso8601String(),
      },
    );
    return Driver.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Driver> updateDriver(String id, Map<String, dynamic> updates) async {
    final response = await _apiClient.patch('/drivers/$id', data: updates);
    return Driver.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Driver> updateStatus(String driverId, DriverStatus status) async {
    final response = await _apiClient.patch(
      '/drivers/$driverId/status',
      data: {'status': status.name},
    );
    return Driver.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Driver> updateLocation(String driverId, double lat, double lng) async {
    final response = await _apiClient.patch(
      '/drivers/$driverId/location',
      data: {
        'latitude': lat,
        'longitude': lng,
      },
    );
    return Driver.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteDriver(String id) async {
    await _apiClient.delete('/drivers/$id');
  }

  Future<List<Driver>> getAvailableDrivers() async {
    final response = await _apiClient.get('/drivers/available');
    final data = response.data['data'] as List;
    return data.map((json) => Driver.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getDriverStats(String driverId) async {
    final response = await _apiClient.get('/drivers/$driverId/stats');
    return response.data as Map<String, dynamic>;
  }
}
