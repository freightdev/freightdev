import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = [
      Course('E.L.D.A. Dispatching Course', 'Complete guide to freight dispatching', 12, Icons.school, 65),
      Course('E.L.D.A. Assistant Course', 'Master the AI assistant features', 8, Icons.assistant, 100),
      Course('E.L.D.A. Logistics Course', 'Advanced logistics and route planning', 15, Icons.route, 30),
      Course('E.L.D.A. Effortless Course', 'Streamline your daily operations', 10, Icons.bolt, 0),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Center'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Courses', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            ...courses.map((course) => _buildCourseCard(context, course)),
            const SizedBox(height: 24),
            Text('Learning Resources', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            _buildResourceCard(context, 'Documentation', Icons.book),
            _buildResourceCard(context, 'Video Tutorials', Icons.video_library),
            _buildResourceCard(context, 'Community Forum', Icons.forum),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.purplePrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(course.icon, color: AppTheme.purplePrimary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(course.description, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Text('${course.lessons} lessons', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary)),
                    ],
                  ),
                ),
              ],
            ),
            if (course.progress > 0) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progress', style: Theme.of(context).textTheme.bodySmall),
                      Text('${course.progress}%', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(value: course.progress / 100, color: AppTheme.success),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: Text(course.progress > 0 ? 'Continue' : 'Start Course'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(BuildContext context, String title, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.purplePrimary),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }
}

class Course {
  final String title;
  final String description;
  final int lessons;
  final IconData icon;
  final int progress;
  Course(this.title, this.description, this.lessons, this.icon, this.progress);
}
