import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/document_provider.dart';
import '../../models/document.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(filteredDocumentsProvider);
    final statsAsync = ref.watch(documentStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppTheme.purplePrimary,
        label: const Text('Upload'),
        icon: const Icon(Icons.upload_file),
      ),
      body: Column(
        children: [
          // Stats
          statsAsync.when(
            data: (stats) => Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: _buildStatCard(context, 'Total', stats['total']?.toString() ?? '0')),
                  Expanded(child: _buildStatCard(context, 'Verified', stats['verified']?.toString() ?? '0')),
                  Expanded(child: _buildStatCard(context, 'Pending', stats['pending']?.toString() ?? '0')),
                  Expanded(child: _buildStatCard(context, 'Expired', stats['expired']?.toString() ?? '0')),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Documents List
          Expanded(
            child: documentsAsync.when(
              data: (documents) => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final doc = documents[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(_getDocIcon(doc.type)),
                      title: Text(doc.name),
                      subtitle: Text('${doc.category} • ${doc.fileSizeFormatted}'),
                      trailing: _buildStatusChip(doc.status),
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
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  IconData _getDocIcon(DocumentType type) {
    switch (type) {
      case DocumentType.license:
        return Icons.badge;
      case DocumentType.insurance:
        return Icons.security;
      default:
        return Icons.description;
    }
  }

  Widget _buildStatusChip(DocumentStatus status) {
    Color color;
    switch (status) {
      case DocumentStatus.verified:
        color = AppTheme.success;
        break;
      case DocumentStatus.pending:
        color = AppTheme.warning;
        break;
      case DocumentStatus.expired:
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
