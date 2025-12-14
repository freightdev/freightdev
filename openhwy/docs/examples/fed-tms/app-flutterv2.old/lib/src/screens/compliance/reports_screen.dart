import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = [
      ReportType('Revenue Report', 'Track income and earnings', Icons.attach_money, AppTheme.success),
      ReportType('Loads Report', 'Analyze load performance', Icons.local_shipping, AppTheme.info),
      ReportType('Carriers Report', 'Carrier statistics and metrics', Icons.business, AppTheme.purplePrimary),
      ReportType('Commission Report', 'Commission breakdown', Icons.percent, AppTheme.warning),
      ReportType('Insurance Report', 'Insurance and compliance', Icons.security, AppTheme.error),
      ReportType('Safety Report', 'Safety metrics and incidents', Icons.health_and_safety, Colors.orange),
      ReportType('Schedule Report', 'Timeline and scheduling', Icons.schedule, Colors.blue),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: () {}),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick stats
            Text('Quick Stats', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard(context, 'This Month', '\$47,250', Icons.trending_up, AppTheme.success)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(context, 'Total Loads', '142', Icons.inventory, AppTheme.info)),
              ],
            ),
            const SizedBox(height: 24),

            // Reports
            Text('Available Reports', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: reports.length,
              itemBuilder: (context, index) => _buildReportCard(context, reports[index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, ReportType report) {
    return Card(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(report.icon, size: 40, color: report.color),
              const SizedBox(height: 12),
              Text(
                report.title,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                report.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportType {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  ReportType(this.title, this.description, this.icon, this.color);
}
