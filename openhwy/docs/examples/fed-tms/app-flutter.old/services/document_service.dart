import 'package:dio/dio.dart';
import '../models/document.dart';
import 'api_client.dart';

class DocumentService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Document>> getDocuments({
    String? search,
    DocumentType? type,
    DocumentStatus? status,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (type != null) 'type': type.name,
      if (status != null) 'status': status.name,
    };

    final response = await _apiClient.get('/documents', queryParameters: queryParams);
    final data = response.data['data'] as List;
    return data.map((json) => Document.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Document> getDocument(String id) async {
    final response = await _apiClient.get('/documents/$id');
    return Document.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Document> uploadDocument({
    required String name,
    required DocumentType type,
    required String category,
    required String filePath,
    String? driverId,
    String? loadId,
    DateTime? expiresAt,
    String? notes,
  }) async {
    final formData = FormData.fromMap({
      'name': name,
      'type': type.name,
      'category': category,
      'file': await MultipartFile.fromFile(filePath),
      if (driverId != null) 'driver_id': driverId,
      if (loadId != null) 'load_id': loadId,
      if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
      if (notes != null) 'notes': notes,
    });

    final response = await _apiClient.post('/documents', data: formData);
    return Document.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Document> updateDocument(String id, Map<String, dynamic> updates) async {
    final response = await _apiClient.patch('/documents/$id', data: updates);
    return Document.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Document> updateStatus(String documentId, DocumentStatus status) async {
    final response = await _apiClient.patch(
      '/documents/$documentId/status',
      data: {'status': status.name},
    );
    return Document.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteDocument(String id) async {
    await _apiClient.delete('/documents/$id');
  }

  Future<List<Document>> getExpiringDocuments({int daysThreshold = 30}) async {
    final response = await _apiClient.get(
      '/documents/expiring',
      queryParameters: {'days': daysThreshold},
    );
    final data = response.data['data'] as List;
    return data.map((json) => Document.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<Document>> getDriverDocuments(String driverId) async {
    final response = await _apiClient.get('/drivers/$driverId/documents');
    final data = response.data['data'] as List;
    return data.map((json) => Document.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<Document>> getLoadDocuments(String loadId) async {
    final response = await _apiClient.get('/loads/$loadId/documents');
    final data = response.data['data'] as List;
    return data.map((json) => Document.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<String> downloadDocument(String documentId) async {
    final response = await _apiClient.get('/documents/$documentId/download');
    return response.data['download_url'] as String;
  }

  Future<Map<String, dynamic>> getDocumentStats() async {
    final response = await _apiClient.get('/documents/stats');
    return response.data as Map<String, dynamic>;
  }
}
