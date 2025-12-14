import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/app_search_bar.dart';

enum LoadStatus {
  available,
  dispatched,
  inTransit,
  delivered,
  cancelled,
}

class LoadsScreen extends ConsumerStatefulWidget {
  const LoadsScreen({super.key});

  @override
  ConsumerState<LoadsScreen> createState() => _LoadsScreenState();
}

class _LoadsScreenState extends ConsumerState<LoadsScreen> {
  final _searchController = TextEditingController();
  LoadStatus? _filterStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(LoadStatus status) {
    switch (status) {
      case LoadStatus.available:
        return AppColors.blue;
      case LoadStatus.dispatched:
        return AppColors.orange;
      case LoadStatus.inTransit:
        return AppColors.purple;
      case LoadStatus.delivered:
        return AppColors.green;
      case LoadStatus.cancelled:
        return AppColors.textGray;
    }
  }

  String _getStatusText(LoadStatus status) {
    switch (status) {
      case LoadStatus.available:
        return 'Available';
      case LoadStatus.dispatched:
        return 'Dispatched';
      case LoadStatus.inTransit:
        return 'In Transit';
      case LoadStatus.delivered:
        return 'Delivered';
      case LoadStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Loads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to create load screen
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AppSearchBar(
                  controller: _searchController,
                  hint: 'Search loads...',
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _filterStatus == null,
                        onSelected: () {
                          setState(() => _filterStatus = null);
                        },
                      ),
                      ...LoadStatus.values.map((status) {
                        return _FilterChip(
                          label: _getStatusText(status),
                          isSelected: _filterStatus == status,
                          onSelected: () {
                            setState(() => _filterStatus = status);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loads List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 10,
              itemBuilder: (context, index) {
                final status = LoadStatus.values[index % LoadStatus.values.length];
                final statusColor = _getStatusColor(status);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientNight,
                    border: Border.all(color: AppColors.borderGray),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        context.push('/loads/${1000 + index}');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Load #L${1000 + index}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: statusColor.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Text(
                                    _getStatusText(status),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: AppColors.textGray,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Chicago, IL → Dallas, TX',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textGray,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: AppColors.textGray,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Dec ${12 + index}, 2024',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textGray,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.attach_money,
                                  size: 16,
                                  color: AppColors.green,
                                ),
                                Text(
                                  '\$${2500 + (index * 100)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.purple,
        onPressed: () {
          // Navigate to create load
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelected,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.purple.withOpacity(0.2)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppColors.purple : AppColors.borderGray,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.purple : AppColors.textGray,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
