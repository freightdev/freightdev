import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';

// Invoice Service Provider
final invoiceServiceProvider = Provider<InvoiceService>((ref) => InvoiceService());

// Invoices List Provider with filters
final invoicesProvider = FutureProvider.family<List<Invoice>, InvoiceFilters>((ref, filters) async {
  final invoiceService = ref.watch(invoiceServiceProvider);
  return await invoiceService.getInvoices(
    search: filters.search,
    status: filters.status,
    page: filters.page,
    limit: filters.limit,
  );
});

// Single Invoice Provider
final invoiceProvider = FutureProvider.family<Invoice, String>((ref, invoiceId) async {
  final invoiceService = ref.watch(invoiceServiceProvider);
  return await invoiceService.getInvoice(invoiceId);
});

// Invoice Stats Provider
final invoiceStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final invoiceService = ref.watch(invoiceServiceProvider);
  return await invoiceService.getInvoiceStats();
});

// Invoice Filters State
class InvoiceFilters {
  final String? search;
  final InvoiceStatus? status;
  final int page;
  final int limit;

  const InvoiceFilters({
    this.search,
    this.status,
    this.page = 1,
    this.limit = 50,
  });

  InvoiceFilters copyWith({
    String? search,
    InvoiceStatus? status,
    int? page,
    int? limit,
  }) {
    return InvoiceFilters(
      search: search ?? this.search,
      status: status ?? this.status,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

// Invoice Filters State Notifier
class InvoiceFiltersNotifier extends Notifier<InvoiceFilters> {
  @override
  InvoiceFilters build() => const InvoiceFilters();

  void setSearch(String? search) {
    state = state.copyWith(search: search, page: 1);
  }

  void setStatus(InvoiceStatus? status) {
    state = state.copyWith(status: status, page: 1);
  }

  void setPage(int page) {
    state = state.copyWith(page: page);
  }

  void reset() {
    state = const InvoiceFilters();
  }
}

final invoiceFiltersProvider = NotifierProvider<InvoiceFiltersNotifier, InvoiceFilters>(() {
  return InvoiceFiltersNotifier();
});

// Filtered Invoices Provider
final filteredInvoicesProvider = FutureProvider<List<Invoice>>((ref) async {
  final filters = ref.watch(invoiceFiltersProvider);
  return ref.watch(invoicesProvider(filters).future);
});
