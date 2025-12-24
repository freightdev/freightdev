import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/invoice_provider.dart';
import '../../utils/theme.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(invoiceProvider(invoiceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: () {}),
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
      ),
      body: invoiceAsync.when(
        data: (invoice) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(invoice.number, style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Driver: ${invoice.driverName ?? 'Unknown'}'),
                      const SizedBox(height: 8),
                      Text('Amount: \$${invoice.amount.toStringAsFixed(2)}'),
                      Text('Paid: \$${invoice.paidAmount.toStringAsFixed(2)}'),
                      Text('Remaining: \$${invoice.remainingAmount.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      Text('Status: ${invoice.status.name}'),
                      Text('Due Date: ${invoice.dueDate.toString().split(' ')[0]}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
