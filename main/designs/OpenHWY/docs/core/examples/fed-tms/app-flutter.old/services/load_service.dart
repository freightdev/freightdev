import '../models/load.dart';
import 'api_client.dart';

class LoadService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Load>> getLoads({
    String? search,
    LoadStatus? status,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null) 'status': status.name,
    };

    final response = await _apiClient.get('/loads', queryParameters: queryParams);
    final data = response.data['data'] as List;
    return data.map((json) => Load.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Load> getLoad(String id) async {
    final response = await _apiClient.get('/loads/$id');
    return Load.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Load> createLoad({
    required String reference,
    required String origin,
    required String destination,
    required double rate,
    int? distance,
    DateTime? pickupDate,
    DateTime? deliveryDate,
    String? notes,
  }) async {
    final response = await _apiClient.post(
      '/loads',
      data: {
        'reference': reference,
        'origin': origin,
        'destination': destination,
        'rate': rate,
        if (distance != null) 'distance': distance,
        if (pickupDate != null) 'pickup_date': pickupDate.toIso8601String(),
        if (deliveryDate != null) 'delivery_date': deliveryDate.toIso8601String(),
        if (notes != null) 'notes': notes,
      },
    );
    return Load.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Load> updateLoad(String id, Map<String, dynamic> updates) async {
    final response = await _apiClient.patch('/loads/$id', data: updates);
    return Load.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Load> assignDriver(String loadId, String driverId) async {
    final response = await _apiClient.post(
      '/loads/$loadId/assign',
      data: {'driver_id': driverId},
    );
    return Load.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Load> updateStatus(String loadId, LoadStatus status) async {
    final response = await _apiClient.patch(
      '/loads/$loadId/status',
      data: {'status': status.name},
    );
    return Load.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteLoad(String id) async {
    await _apiClient.delete('/loads/$id');
  }

  Future<Map<String, dynamic>> getLoadStats() async {
    final response = await _apiClient.get('/loads/stats');
    return response.data as Map<String, dynamic>;
  }
}
