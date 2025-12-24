import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/models/invoice_model_full.dart';

class InvoicesListScreen extends StatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  State<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends State<InvoicesListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
          'Invoices',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        actions: [
          AppButton(
            label: 'Create Invoice',
            icon: Icons.add,
            size: AppButtonSize.small,
            onPressed: () {},
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
            Tab(text: 'Draft'),
            Tab(text: 'Sent'),
            Tab(text: 'Paid'),
            Tab(text: 'Overdue'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Summary Cards
          Container(
            color: AppColors.asphaltGray,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Total Outstanding',
                    value: '\$28,450',
                    color: AppColors.warningOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: 'Overdue',
                    value: '\$4,200',
                    color: AppColors.truckRed,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInvoicesList(null),
                _buildInvoicesList(InvoiceStatus.draft),
                _buildInvoicesList(InvoiceStatus.sent),
                _buildInvoicesList(InvoiceStatus.paid),
                _buildInvoicesList(InvoiceStatus.overdue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesList(InvoiceStatus? status) {
    final mockInvoices = _generateMockInvoices(status);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockInvoices.length,
      itemBuilder: (context, index) {
        return _InvoiceCard(
          invoice: mockInvoices[index],
          onTap: () {
            // TODO: Navigate to invoice detail
          },
        );
      },
    );
  }

  List<Invoice> _generateMockInvoices(InvoiceStatus? status) {
    final allInvoices = [
      Invoice(
        id: '1',
        invoiceNumber: 'INV-2024-001',
        customerName: 'ABC Logistics',
        customerEmail: 'billing@abclogistics.com',
        status: InvoiceStatus.paid,
        issueDate: DateTime.now().subtract(const Duration(days: 30)),
        dueDate: DateTime.now().subtract(const Duration(days: 15)),
        paidDate: DateTime.now().subtract(const Duration(days: 10)),
        lineItems: [
          const InvoiceLineItem(
            id: '1',
            description: 'Load LD-2024-001',
            quantity: 1,
            rate: 2500,
            amount: 2500,
          ),
        ],
        subtotal: 2500,
        taxRate: 0,
        taxAmount: 0,
        total: 2500,
        amountPaid: 2500,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Invoice(
        id: '2',
        invoiceNumber: 'INV-2024-002',
        customerName: 'XYZ Freight',
        customerEmail: 'ap@xyzfreight.com',
        status: InvoiceStatus.overdue,
        issueDate: DateTime.now().subtract(const Duration(days: 45)),
        dueDate: DateTime.now().subtract(const Duration(days: 15)),
        lineItems: [
          const InvoiceLineItem(
            id: '2',
            description: 'Load LD-2024-002',
            quantity: 1,
            rate: 1800,
            amount: 1800,
          ),
        ],
        subtotal: 1800,
        taxRate: 0,
        taxAmount: 0,
        total: 1800,
        amountPaid: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Invoice(
        id: '3',
        invoiceNumber: 'INV-2024-003',
        customerName: 'Global Shipping Co',
        customerEmail: 'invoices@globalship.com',
        status: InvoiceStatus.sent,
        issueDate: DateTime.now().subtract(const Duration(days: 5)),
        dueDate: DateTime.now().add(const Duration(days: 25)),
        lineItems: [
          const InvoiceLineItem(
            id: '3',
            description: 'Load LD-2024-003',
            quantity: 1,
            rate: 3200,
            amount: 3200,
          ),
        ],
        subtotal: 3200,
        taxRate: 0,
        taxAmount: 0,
        total: 3200,
        amountPaid: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    if (status == null) return allInvoices;
    return allInvoices.where((inv) => inv.status == status).toList();
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.gradientNight,
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;

  const _InvoiceCard({
    required this.invoice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.invoiceNumber,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            invoice.customerName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _InvoiceStatusBadge(status: invoice.status),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: AppColors.borderLight,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textGray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '\$${invoice.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forestGreen,
                          ),
                        ),
                      ],
                    ),
                    if (invoice.status != InvoiceStatus.paid)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Due Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textGray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatDate(invoice.dueDate),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: invoice.isOverdue
                                  ? AppColors.truckRed
                                  : AppColors.white,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _InvoiceStatusBadge extends StatelessWidget {
  final InvoiceStatus status;

  const _InvoiceStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getLabel(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _getTextColor(),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _getLabel() {
    switch (status) {
      case InvoiceStatus.draft:
        return 'DRAFT';
      case InvoiceStatus.sent:
        return 'SENT';
      case InvoiceStatus.paid:
        return 'PAID';
      case InvoiceStatus.overdue:
        return 'OVERDUE';
      case InvoiceStatus.cancelled:
        return 'CANCELLED';
    }
  }

  Color _getBackgroundColor() {
    switch (status) {
      case InvoiceStatus.draft:
        return AppColors.textGray.withOpacity(0.2);
      case InvoiceStatus.sent:
        return AppColors.highwayBlue.withOpacity(0.2);
      case InvoiceStatus.paid:
        return AppColors.forestGreen.withOpacity(0.2);
      case InvoiceStatus.overdue:
        return AppColors.truckRed.withOpacity(0.2);
      case InvoiceStatus.cancelled:
        return AppColors.textGray.withOpacity(0.2);
    }
  }

  Color _getTextColor() {
    switch (status) {
      case InvoiceStatus.draft:
        return AppColors.textGray;
      case InvoiceStatus.sent:
        return AppColors.highwayBlue;
      case InvoiceStatus.paid:
        return AppColors.forestGreen;
      case InvoiceStatus.overdue:
        return AppColors.truckRed;
      case InvoiceStatus.cancelled:
        return AppColors.textGray;
    }
  }
}
