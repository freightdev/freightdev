import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/driver_provider.dart';
import '../../models/driver.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';

class DriversScreen extends ConsumerWidget {
  const DriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(filteredDriversProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Drivers')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppTheme.purplePrimary,
        label: const Text('Add Driver'),
        icon: const Icon(Icons.person_add),
      ),
      body: driversAsync.when(
        data: (drivers) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: drivers.length,
          itemBuilder: (context, index) {
            final driver = drivers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.purplePrimary,
                  child: Text(driver.initials),
                ),
                title: Text(driver.fullName),
                subtitle: Text(driver.email),
                trailing: Icon(
                  Icons.circle,
                  size: 12,
                  color: driver.status == DriverStatus.online
                      ? AppTheme.success
                      : AppTheme.textTertiary,
                ),
                onTap: () => context.push('/drivers/${driver.id}'),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
