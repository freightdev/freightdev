import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/models/loadboard_model.dart';
import '../widgets/load_card.dart';

class LoadsListScreen extends StatefulWidget {
  const LoadsListScreen({super.key});

  @override
  State<LoadsListScreen> createState() => _LoadsListScreenState();
}

class _LoadsListScreenState extends State<LoadsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  LoadStatus? _filterStatus;
  String? _filterDriver;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.roadBlack,
      appBar: AppBar(
        backgroundColor: AppColors.asphaltGray,
        title: const Text(
          'Loads',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        actions: [
          AppButton(
            label: 'Add Load',
            icon: Icons.add,
            size: AppButtonSize.small,
            onPressed: () {
              // TODO: Navigate to create load screen
            },
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.sunrisePurple,
          indicatorWeight: 3,
          labelColor: AppColors.sunrisePurple,
          unselectedLabelColor: AppColors.textGray,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Booked'),
            Tab(text: 'In Transit'),
            Tab(text: 'Delivered'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.asphaltGray,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    hintText: 'Search loads...',
                    hintStyle: const TextStyle(color: AppColors.textGray),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textGray),
                    filled: true,
                    fillColor: AppColors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderGray),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderGray),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.sunrisePurple),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Driver',
                          labelStyle: const TextStyle(color: AppColors.textGray),
                          filled: true,
                          fillColor: AppColors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.borderGray),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.borderGray),
                          ),
                        ),
                        dropdownColor: AppColors.concreteGray,
                        style: const TextStyle(color: AppColors.white),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All Drivers')),
                          DropdownMenuItem(value: 'john', child: Text('John Smith')),
                          DropdownMenuItem(value: 'jane', child: Text('Jane Doe')),
                        ],
                        onChanged: (value) {
                          setState(() => _filterDriver = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      label: 'Clear',
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.small,
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _filterStatus = null;
                          _filterDriver = null;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLoadsList(null),
                _buildLoadsList(LoadStatus.pending),
                _buildLoadsList(LoadStatus.booked),
                _buildLoadsList(LoadStatus.inTransit),
                _buildLoadsList(LoadStatus.delivered),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadsList(LoadStatus? status) {
    // TODO: Replace with actual data from provider/state management
    final mockLoads = _generateMockLoads(status);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockLoads.length,
      itemBuilder: (context, index) {
        return LoadCard(
          load: mockLoads[index],
          onTap: () {
            // TODO: Navigate to load detail screen
          },
        );
      },
    );
  }

  List<Load> _generateMockLoads(LoadStatus? status) {
    // Mock data - replace with actual data
    final allLoads = [
      Load(
        id: '1',
        reference: 'LD-2024-001',
        origin: 'Chicago, IL',
        destination: 'Dallas, TX',
        status: LoadStatus.inTransit,
        rate: 2500.00,
        distance: 920,
        driverId: 'driver1',
        driverName: 'John Smith',
        progress: 45,
        pickupDate: DateTime.now().subtract(const Duration(days: 1)),
        deliveryDate: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Load(
        id: '2',
        reference: 'LD-2024-002',
        origin: 'Los Angeles, CA',
        destination: 'Phoenix, AZ',
        status: LoadStatus.pending,
        rate: 1800.00,
        distance: 375,
        pickupDate: DateTime.now().add(const Duration(days: 2)),
        deliveryDate: DateTime.now().add(const Duration(days: 3)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Load(
        id: '3',
        reference: 'LD-2024-003',
        origin: 'Atlanta, GA',
        destination: 'Miami, FL',
        status: LoadStatus.booked,
        rate: 1500.00,
        distance: 660,
        driverId: 'driver2',
        driverName: 'Jane Doe',
        pickupDate: DateTime.now().add(const Duration(days: 1)),
        deliveryDate: DateTime.now().add(const Duration(days: 2)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Load(
        id: '4',
        reference: 'LD-2024-004',
        origin: 'Seattle, WA',
        destination: 'Denver, CO',
        status: LoadStatus.delivered,
        rate: 3200.00,
        distance: 1315,
        driverId: 'driver1',
        driverName: 'John Smith',
        progress: 100,
        pickupDate: DateTime.now().subtract(const Duration(days: 3)),
        deliveryDate: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    if (status == null) return allLoads;
    return allLoads.where((load) => load.status == status).toList();
  }
}
