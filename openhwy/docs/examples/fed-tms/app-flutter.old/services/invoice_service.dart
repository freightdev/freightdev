import '../models/invoice.dart';
import 'api_client.dart';

class InvoiceService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Invoice>> getInvoices({
    String? search,
    InvoiceStatus? status,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null) 'status': status.name,
    };

    final response = await _apiClient.get('/invoices', queryParameters: queryParams);
    final data = response.data['data'] as List;
    return data.map((json) => Invoice.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Invoice> getInvoice(String id) async {
    final response = await _apiClient.get('/invoices/$id');
    return Invoice.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Invoice> createInvoice({
    required String loadId,
    required double amount,
    required DateTime dueDate,
    String? notes,
  }) async {
    final response = await _apiClient.post(
      '/invoices',
      data: {
        'load_id': loadId,
        'amount': amount,
        'due_date': dueDate.toIso8601String(),
        if (notes != null) 'notes': notes,
      },
    );
    return Invoice.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Invoice> updateInvoice(String id, Map<String, dynamic> updates) async {
    final response = await _apiClient.patch('/invoices/$id', data: updates);
    return Invoice.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Invoice> recordPayment(String invoiceId, double amount) async {
    final response = await _apiClient.post(
      '/invoices/$invoiceId/payments',
      data: {'amount': amount},
    );
    return Invoice.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Invoice> updateStatus(String invoiceId, InvoiceStatus status) async {
    final response = await _apiClient.patch(
      '/invoices/$invoiceId/status',
      data: {'status': status.name},
    );
    return Invoice.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteInvoice(String id) async {
    await _apiClient.delete('/invoices/$id');
  }

  Future<Map<String, dynamic>> getInvoiceStats() async {
    final response = await _apiClient.get('/invoices/stats');
    return response.data as Map<String, dynamic>;
  }

  Future<String> generatePDF(String invoiceId) async {
    final response = await _apiClient.get('/invoices/$invoiceId/pdf');
    return response.data['pdf_url'] as String;
  }
}
