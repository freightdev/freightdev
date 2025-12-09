import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';

class EldScreen extends ConsumerStatefulWidget {
  const EldScreen({super.key});

  @override
  ConsumerState<EldScreen> createState() => _EldScreenState();
}

class _EldScreenState extends ConsumerState<EldScreen> {
  String _selectedDriver = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ELD & HOS'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Driver selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.surfaceGradient,
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedDriver,
              decoration: const InputDecoration(
                labelText: 'Select Driver',
                prefixIcon: Icon(Icons.person),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Drivers')),
                DropdownMenuItem(value: 'john', child: Text('John Smith')),
                DropdownMenuItem(value: 'sarah', child: Text('Sarah Johnson')),
              ],
              onChanged: (value) => setState(() => _selectedDriver = value!),
            ),
          ),

          // HOS Status Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _buildHosCard('Drive Time', '08:45', '11:00', AppTheme.info)),
                const SizedBox(width: 12),
                Expanded(child: _buildHosCard('On Duty', '12:30', '14:00', AppTheme.warning)),
              ],
            ),
          ),

          // Log entries
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (context, index) => _buildLogEntry(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHosCard(String title, String used, String total, Color color) {
    final percentage = _parseTime(used) / _parseTime(total);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text('$used / $total', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: percentage, color: color),
          ],
        ),
      ),
    );
  }

  double _parseTime(String time) {
    final parts = time.split(':');
    return double.parse(parts[0]) + double.parse(parts[1]) / 60;
  }

  Widget _buildLogEntry() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.drive_eta, color: AppTheme.info),
        title: const Text('Driving'),
        subtitle: const Text('Started: 08:00 AM • Duration: 2h 15m'),
        trailing: const Text('Active'),
      ),
    );
  }
}
