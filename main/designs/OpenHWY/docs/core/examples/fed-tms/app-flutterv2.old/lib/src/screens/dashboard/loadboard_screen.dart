import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/load_provider.dart';
import '../../utils/theme.dart';

class LoadDetailScreen extends ConsumerWidget {
  final String loadId;

  const LoadDetailScreen({super.key, required this.loadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadAsync = ref.watch(loadProvider(loadId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Load Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
          ),
        ],
      ),
      body: loadAsync.when(
        data: (load) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                load.reference,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Route', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Text('From: ${load.origin}'),
                      const SizedBox(height: 8),
                      Text('To: ${load.destination}'),
                      const SizedBox(height: 16),
                      Text('Rate: \$${load.rate.toStringAsFixed(2)}'),
                      if (load.distance != null)
                        Text('Distance: ${load.distance} miles'),
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
