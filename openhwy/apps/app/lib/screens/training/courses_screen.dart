import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/app_search_bar.dart';

enum CourseCategory {
  safety,
  compliance,
  dispatch,
  operations,
  customer_service,
}

enum CourseStatus {
  notStarted,
  inProgress,
  completed,
}

class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  final _searchController = TextEditingController();
  CourseCategory? _filterCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(CourseCategory category) {
    switch (category) {
      case CourseCategory.safety:
        return AppColors.error;
      case CourseCategory.compliance:
        return AppColors.blue;
      case CourseCategory.dispatch:
        return AppColors.purple;
      case CourseCategory.operations:
        return AppColors.orange;
      case CourseCategory.customer_service:
        return AppColors.green;
    }
  }

  String _getCategoryText(CourseCategory category) {
    switch (category) {
      case CourseCategory.safety:
        return 'Safety';
      case CourseCategory.compliance:
        return 'Compliance';
      case CourseCategory.dispatch:
        return 'Dispatch';
      case CourseCategory.operations:
        return 'Operations';
      case CourseCategory.customer_service:
        return 'Customer Service';
    }
  }

  Color _getStatusColor(CourseStatus status) {
    switch (status) {
      case CourseStatus.notStarted:
        return AppColors.textGray;
      case CourseStatus.inProgress:
        return AppColors.orange;
      case CourseStatus.completed:
        return AppColors.green;
    }
  }

  String _getStatusText(CourseStatus status) {
    switch (status) {
      case CourseStatus.notStarted:
        return 'Not Started';
      case CourseStatus.inProgress:
        return 'In Progress';
      case CourseStatus.completed:
        return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Training'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AppSearchBar(
                  controller: _searchController,
                  hint: 'Search courses...',
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
                        isSelected: _filterCategory == null,
                        onSelected: () {
                          setState(() => _filterCategory = null);
                        },
                      ),
                      ...CourseCategory.values.map((category) {
                        return _FilterChip(
                          label: _getCategoryText(category),
                          isSelected: _filterCategory == category,
                          onSelected: () {
                            setState(() => _filterCategory = category);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Progress Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.gradientNight,
                border: Border.all(color: AppColors.borderGray),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ProgressStat(
                    label: 'Completed',
                    value: '12',
                    color: AppColors.green,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.borderGray,
                  ),
                  _ProgressStat(
                    label: 'In Progress',
                    value: '3',
                    color: AppColors.orange,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.borderGray,
                  ),
                  _ProgressStat(
                    label: 'Total Hours',
                    value: '24.5',
                    color: AppColors.purple,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Courses List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 15,
              itemBuilder: (context, index) {
                final category = CourseCategory.values[index % CourseCategory.values.length];
                final status = CourseStatus.values[index % CourseStatus.values.length];
                final categoryColor = _getCategoryColor(category);
                final statusColor = _getStatusColor(status);
                final progress = status == CourseStatus.completed
                    ? 1.0
                    : status == CourseStatus.inProgress
                        ? (index % 10) / 10
                        : 0.0;

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
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: categoryColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: categoryColor.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Text(
                                    _getCategoryText(category),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: categoryColor,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: statusColor.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Text(
                                    _getStatusText(status),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _getCourseName(index),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Learn the fundamentals of ${_getCategoryText(category).toLowerCase()} in the trucking industry',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textGray,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: AppColors.textGray,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${2 + (index % 3)}h ${(index % 6) * 10}m',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textGray,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.play_circle,
                                  size: 14,
                                  color: AppColors.textGray,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${8 + index} lessons',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textGray,
                                  ),
                                ),
                              ],
                            ),
                            if (status != CourseStatus.notStarted) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: AppColors.borderGray,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          categoryColor,
                                        ),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${(progress * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: categoryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
    );
  }

  String _getCourseName(int index) {
    final names = [
      'Introduction to DOT Regulations',
      'Advanced HOS Management',
      'Customer Service Excellence',
      'Load Planning & Optimization',
      'Defensive Driving Techniques',
      'ELD Compliance Training',
      'Freight Broker Relations',
      'Route Planning Strategies',
      'Vehicle Inspection Procedures',
      'Emergency Response Protocol',
    ];
    return names[index % names.length];
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

class _ProgressStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ProgressStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textGray,
          ),
        ),
      ],
    );
  }
}
