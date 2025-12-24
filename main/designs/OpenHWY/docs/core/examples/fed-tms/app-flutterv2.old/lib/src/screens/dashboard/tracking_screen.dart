import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Tracking')),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.surfaceGradient,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 64, color: AppTheme.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'Live GPS Tracking Map',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Integrate with Google Maps / Mapbox',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Active Loads', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _buildActiveLoadCard(context, 'LOAD-001', 'John Smith', 65),
                _buildActiveLoadCard(context, 'LOAD-004', 'Sarah Johnson', 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLoadCard(BuildContext context, String ref, String driver, int progress) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ref, style: Theme.of(context).textTheme.titleMedium),
            Text(driver, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress / 100),
            const SizedBox(height: 4),
            Text('$progress% complete', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
