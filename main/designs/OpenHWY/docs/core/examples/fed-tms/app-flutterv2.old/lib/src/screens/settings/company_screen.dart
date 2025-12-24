import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/local_storage_service.dart';
import '../../utils/theme.dart';

class CompanySettingsScreen extends ConsumerStatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  ConsumerState<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends ConsumerState<CompanySettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final company = LocalStorageService.getCurrentCompany();

    if (company == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Company Settings')),
        body: const Center(child: Text('No company data found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Settings'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Basic Information', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _buildInfoRow('Company Name', company.name),
                  if (company.legalName != null) _buildInfoRow('Legal Name', company.legalName!),
                  if (company.ein != null) _buildInfoRow('EIN', company.ein!),
                  if (company.mcNumber != null) _buildInfoRow('MC Number', company.mcNumber!),
                  if (company.dotNumber != null) _buildInfoRow('DOT Number', company.dotNumber!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Contact Information', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  if (company.address != null) _buildInfoRow('Address', company.address!),
                  if (company.city != null && company.state != null)
                    _buildInfoRow('City, State', '${company.city}, ${company.state}'),
                  if (company.zipCode != null) _buildInfoRow('ZIP Code', company.zipCode!),
                  if (company.phone != null) _buildInfoRow('Phone', company.phone!),
                  if (company.email != null) _buildInfoRow('Email', company.email!),
                  if (company.website != null) _buildInfoRow('Website', company.website!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
          ),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
