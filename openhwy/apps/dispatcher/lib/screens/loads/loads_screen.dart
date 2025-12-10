import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/load.dart';
import '../../providers/load_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';

class LoadsScreen extends ConsumerStatefulWidget {
  const LoadsScreen({super.key});

  @override
  ConsumerState<LoadsScreen> createState() => _LoadsScreenState();
}

class _LoadsScreenState extends ConsumerState<LoadsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loadsAsync = ref.watch(filteredLoadsProvider);
    final filters = ref.watch(loadFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to create load screen
        },
        backgroundColor: AppTheme.purplePrimary,
        label: const Text('Create Load'),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.surfaceGradient,
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by reference, origin, or destination...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(loadFiltersProvider.notifier).setSearch(null);
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(loadFiltersProvider.notifier).setSearch(
                      value.isEmpty ? null : value,
                    );
              },
            ),
          ),

          // Active Filters
          if (filters.status != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.surface,
              child: Wrap(
                spacing: 8,
                children: [
                  if (filters.status != null)
                    Chip(
                      label: Text('Status: ${filters.status!.name}'),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        ref.read(loadFiltersProvider.notifier).setStatus(null);
                      },
                    ),
                ],
              ),
            ),

          // Loads List
          Expanded(
            child: loadsAsync.when(
              data: (loads) {
                if (loads.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 64,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No loads found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(filteredLoadsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: loads.length,
                    itemBuilder: (context, index) {
                      final load = loads[index];
                      return _buildLoadCard(context, load);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppTheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading loads',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString().replaceAll('Exception: ', ''),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(filteredLoadsProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadCard(BuildContext context, Load load) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/loads/${load.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    load.reference,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.purplePrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  _buildStatusBadge(load.status),
                ],
              ),
              const SizedBox(height: 12),

              // Route
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${load.origin} → ${load.destination}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Details Row
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Driver',
                      load.driverName ?? 'Unassigned',
                      Icons.person,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Rate',
                      '\$${load.rate.toStringAsFixed(2)}',
                      Icons.attach_money,
                    ),
                  ),
                  if (load.distance != null)
                    Expanded(
                      child: _buildDetailItem(
                        'Distance',
                        '${load.distance} mi',
                        Icons.straighten,
                      ),
                    ),
                ],
              ),

              // Progress Bar (if in transit)
              if (load.progress != null && load.progress! > 0) ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${load.progress}%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: load.progress! / 100,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProgressColor(load.status),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textTertiary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(LoadStatus status) {
    Color color;
    String text;

    switch (status) {
      case LoadStatus.pending:
        color = AppTheme.warning;
        text = 'Pending';
        break;
      case LoadStatus.booked:
        color = AppTheme.info;
        text = 'Booked';
        break;
      case LoadStatus.inTransit:
        color = AppTheme.info;
        text = 'In Transit';
        break;
      case LoadStatus.delivered:
        color = AppTheme.success;
        text = 'Delivered';
        break;
      case LoadStatus.cancelled:
        color = AppTheme.error;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getProgressColor(LoadStatus status) {
    switch (status) {
      case LoadStatus.inTransit:
        return AppTheme.info;
      case LoadStatus.delivered:
        return AppTheme.success;
      default:
        return AppTheme.purplePrimary;
    }
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final filters = ref.watch(loadFiltersProvider);

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Loads',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: filters.status == null,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(loadFiltersProvider.notifier).setStatus(null);
                        }
                      },
                    ),
                    ...LoadStatus.values.map((status) {
                      return ChoiceChip(
                        label: Text(status.name),
                        selected: filters.status == status,
                        onSelected: (selected) {
                          ref.read(loadFiltersProvider.notifier).setStatus(
                                selected ? status : null,
                              );
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(loadFiltersProvider.notifier).reset();
                          Navigator.pop(context);
                        },
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
