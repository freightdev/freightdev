import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/app_button.dart';

enum DocumentType {
  rateConfirmation,
  bol,
  pod,
  invoice,
  insurance,
  license,
  other,
}

class DocumentsManagerScreen extends StatefulWidget {
  const DocumentsManagerScreen({super.key});

  @override
  State<DocumentsManagerScreen> createState() => _DocumentsManagerScreenState();
}

class _DocumentsManagerScreenState extends State<DocumentsManagerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
          'Documents',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        actions: [
          AppButton(
            label: 'Upload',
            icon: Icons.upload_file,
            size: AppButtonSize.small,
            onPressed: () {
              _showUploadDialog();
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
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
            Tab(text: 'Load Docs'),
            Tab(text: 'Driver Docs'),
            Tab(text: 'Company'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDocumentsList(null),
          _buildDocumentsList(DocumentCategory.loads),
          _buildDocumentsList(DocumentCategory.drivers),
          _buildDocumentsList(DocumentCategory.company),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadDialog,
        backgroundColor: AppColors.sunrisePurple,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildDocumentsList(DocumentCategory? category) {
    final documents = _getMockDocuments(category);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        return _DocumentCard(
          document: documents[index],
          onTap: () {
            _showDocumentDetails(documents[index]);
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _getMockDocuments(DocumentCategory? category) {
    return [
      {
        'name': 'Rate Confirmation - LD-2024-001.pdf',
        'type': DocumentType.rateConfirmation,
        'category': DocumentCategory.loads,
        'size': '1.2 MB',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'load': 'LD-2024-001',
      },
      {
        'name': 'Bill of Lading - LD-2024-001.pdf',
        'type': DocumentType.bol,
        'category': DocumentCategory.loads,
        'size': '856 KB',
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'load': 'LD-2024-001',
      },
      {
        'name': 'Proof of Delivery - LD-2024-001.pdf',
        'type': DocumentType.pod,
        'category': DocumentCategory.loads,
        'size': '2.4 MB',
        'date': DateTime.now(),
        'load': 'LD-2024-001',
      },
      {
        'name': 'Driver License - John Smith.pdf',
        'type': DocumentType.license,
        'category': DocumentCategory.drivers,
        'size': '645 KB',
        'date': DateTime.now().subtract(const Duration(days: 30)),
        'driver': 'John Smith',
      },
      {
        'name': 'Insurance Certificate.pdf',
        'type': DocumentType.insurance,
        'category': DocumentCategory.company,
        'size': '1.8 MB',
        'date': DateTime.now().subtract(const Duration(days: 15)),
      },
    ];
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.asphaltGray,
        title: const Text(
          'Upload Document',
          style: TextStyle(color: AppColors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _UploadOptionTile(
              icon: Icons.camera_alt,
              label: 'Take Photo',
              onTap: () {
                Navigator.pop(context);
                // TODO: Open camera
              },
            ),
            _UploadOptionTile(
              icon: Icons.photo_library,
              label: 'Choose from Gallery',
              onTap: () {
                Navigator.pop(context);
                // TODO: Open gallery
              },
            ),
            _UploadOptionTile(
              icon: Icons.insert_drive_file,
              label: 'Choose File',
              onTap: () {
                Navigator.pop(context);
                // TODO: Open file picker
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDocumentDetails(Map<String, dynamic> document) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.asphaltGray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                document['name'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 20),
              _DetailRow(
                icon: Icons.folder,
                label: 'Type',
                value: _getDocumentTypeLabel(document['type']),
              ),
              _DetailRow(
                icon: Icons.storage,
                label: 'Size',
                value: document['size'],
              ),
              _DetailRow(
                icon: Icons.calendar_today,
                label: 'Uploaded',
                value: _formatDate(document['date']),
              ),
              if (document['load'] != null)
                _DetailRow(
                  icon: Icons.local_shipping,
                  label: 'Load',
                  value: document['load'],
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'View',
                      icon: Icons.visibility,
                      variant: AppButtonVariant.secondary,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Share',
                      icon: Icons.share,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _getDocumentTypeLabel(DocumentType type) {
    switch (type) {
      case DocumentType.rateConfirmation:
        return 'Rate Confirmation';
      case DocumentType.bol:
        return 'Bill of Lading';
      case DocumentType.pod:
        return 'Proof of Delivery';
      case DocumentType.invoice:
        return 'Invoice';
      case DocumentType.insurance:
        return 'Insurance';
      case DocumentType.license:
        return 'License';
      case DocumentType.other:
        return 'Other';
    }
  }
}

enum DocumentCategory {
  loads,
  drivers,
  company,
}

class _DocumentCard extends StatelessWidget {
  final Map<String, dynamic> document;
  final VoidCallback onTap;

  const _DocumentCard({
    required this.document,
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getTypeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: _getTypeColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document['name'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            document['size'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textGray,
                            ),
                          ),
                          const Text(
                            ' • ',
                            style: TextStyle(color: AppColors.textGray),
                          ),
                          Text(
                            _formatDate(document['date']),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: AppColors.textGray),
                  onPressed: onTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor() {
    final type = document['type'] as DocumentType;
    switch (type) {
      case DocumentType.rateConfirmation:
      case DocumentType.invoice:
        return AppColors.forestGreen;
      case DocumentType.bol:
      case DocumentType.pod:
        return AppColors.highwayBlue;
      case DocumentType.insurance:
      case DocumentType.license:
        return AppColors.warningOrange;
      case DocumentType.other:
        return AppColors.textGray;
    }
  }

  IconData _getTypeIcon() {
    final type = document['type'] as DocumentType;
    switch (type) {
      case DocumentType.rateConfirmation:
        return Icons.description;
      case DocumentType.bol:
        return Icons.receipt_long;
      case DocumentType.pod:
        return Icons.check_circle;
      case DocumentType.invoice:
        return Icons.receipt;
      case DocumentType.insurance:
        return Icons.security;
      case DocumentType.license:
        return Icons.badge;
      case DocumentType.other:
        return Icons.insert_drive_file;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _UploadOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _UploadOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.sunrisePurple),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textGray, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
