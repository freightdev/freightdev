import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/invoice_provider.dart';
import '../../models/invoice.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';

class InvoicingScreen extends ConsumerWidget {
  const InvoicingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(filteredInvoicesProvider);
    final statsAsync = ref.watch(invoiceStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Invoicing')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppTheme.purplePrimary,
        label: const Text('Create Invoice'),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Stats
          statsAsync.when(
            data: (stats) => Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: _buildStatCard(context, 'Total', '\$${stats['total']?.toStringAsFixed(2) ?? '0'}')),
                  Expanded(child: _buildStatCard(context, 'Paid', '\$${stats['paid']?.toStringAsFixed(2) ?? '0'}')),
                  Expanded(child: _buildStatCard(context, 'Outstanding', '\$${stats['outstanding']?.toStringAsFixed(2) ?? '0'}')),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Invoices List
          Expanded(
            child: invoicesAsync.when(
              data: (invoices) => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: invoices.length,
                itemBuilder: (context, index) {
                  final invoice = invoices[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(invoice.number),
                      subtitle: Text(invoice.driverName ?? 'Unknown'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('\$${invoice.amount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
                          _buildStatusChip(invoice.status),
                        ],
                      ),
                      onTap: () => context.push('/invoicing/${invoice.id}'),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(InvoiceStatus status) {
    Color color;
    switch (status) {
      case InvoiceStatus.paid:
        color = AppTheme.success;
        break;
      case InvoiceStatus.pending:
        color = AppTheme.warning;
        break;
      case InvoiceStatus.overdue:
        color = AppTheme.error;
        break;
      default:
        color = AppTheme.textTertiary;
    }

    return Chip(
      label: Text(status.name, style: TextStyle(color: color, fontSize: 10)),
      padding: EdgeInsets.zero,
    );
  }
}
