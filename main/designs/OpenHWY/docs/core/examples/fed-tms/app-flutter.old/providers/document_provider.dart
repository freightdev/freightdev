import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/document.dart';
import '../services/document_service.dart';

// Document Service Provider
final documentServiceProvider = Provider<DocumentService>((ref) => DocumentService());

// Documents List Provider with filters
final documentsProvider = FutureProvider.family<List<Document>, DocumentFilters>((ref, filters) async {
  final documentService = ref.watch(documentServiceProvider);
  return await documentService.getDocuments(
    search: filters.search,
    type: filters.type,
    status: filters.status,
    page: filters.page,
    limit: filters.limit,
  );
});

// Single Document Provider
final documentProvider = FutureProvider.family<Document, String>((ref, documentId) async {
  final documentService = ref.watch(documentServiceProvider);
  return await documentService.getDocument(documentId);
});

// Expiring Documents Provider
final expiringDocumentsProvider = FutureProvider<List<Document>>((ref) async {
  final documentService = ref.watch(documentServiceProvider);
  return await documentService.getExpiringDocuments();
});

// Driver Documents Provider
final driverDocumentsProvider = FutureProvider.family<List<Document>, String>((ref, driverId) async {
  final documentService = ref.watch(documentServiceProvider);
  return await documentService.getDriverDocuments(driverId);
});

// Load Documents Provider
final loadDocumentsProvider = FutureProvider.family<List<Document>, String>((ref, loadId) async {
  final documentService = ref.watch(documentServiceProvider);
  return await documentService.getLoadDocuments(loadId);
});

// Document Stats Provider
final documentStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final documentService = ref.watch(documentServiceProvider);
  return await documentService.getDocumentStats();
});

// Document Filters State
class DocumentFilters {
  final String? search;
  final DocumentType? type;
  final DocumentStatus? status;
  final int page;
  final int limit;

  const DocumentFilters({
    this.search,
    this.type,
    this.status,
    this.page = 1,
    this.limit = 50,
  });

  DocumentFilters copyWith({
    String? search,
    DocumentType? type,
    DocumentStatus? status,
    int? page,
    int? limit,
  }) {
    return DocumentFilters(
      search: search ?? this.search,
      type: type ?? this.type,
      status: status ?? this.status,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

// Document Filters State Notifier
class DocumentFiltersNotifier extends Notifier<DocumentFilters> {
  @override
  DocumentFilters build() => const DocumentFilters();

  void setSearch(String? search) {
    state = state.copyWith(search: search, page: 1);
  }

  void setType(DocumentType? type) {
    state = state.copyWith(type: type, page: 1);
  }

  void setStatus(DocumentStatus? status) {
    state = state.copyWith(status: status, page: 1);
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
  }

  void reset() {
    state = const DocumentFilters();
  }
}

final documentFiltersProvider = NotifierProvider<DocumentFiltersNotifier, DocumentFilters>(() {
  return DocumentFiltersNotifier();
});

// Filtered Documents Provider
final filteredDocumentsProvider = FutureProvider<List<Document>>((ref) async {
  final filters = ref.watch(documentFiltersProvider);
  return ref.watch(documentsProvider(filters).future);
});
