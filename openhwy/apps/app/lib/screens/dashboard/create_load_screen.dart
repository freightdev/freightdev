import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/models/loadboard_model.dart';

class CreateLoadScreen extends StatefulWidget {
  final String? loadId; // If editing existing load

  const CreateLoadScreen({
    super.key,
    this.loadId,
  });

  @override
  State<CreateLoadScreen> createState() => _CreateLoadScreenState();
}

class _CreateLoadScreenState extends State<CreateLoadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _rateController = TextEditingController();
  final _distanceController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _pickupDate;
  DateTime? _deliveryDate;
  LoadStatus _status = LoadStatus.pending;
  String? _selectedDriver;

  bool _isLoading = false;

  @override
  void dispose() {
    _referenceController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _rateController.dispose();
    _distanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.roadBlack,
      appBar: AppBar(
        backgroundColor: AppColors.asphaltGray,
        title: Text(
          widget.loadId == null ? 'Create Load' : 'Edit Load',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Load Information Section
              _SectionHeader(
                icon: Icons.local_shipping,
                title: 'Load Information',
              ),
              const SizedBox(height: 16),
              _FormCard(
                child: Column(
                  children: [
                    _TextFormField(
                      controller: _referenceController,
                      label: 'Load Reference *',
                      hint: 'LD-2024-001',
                      icon: Icons.tag,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a load reference';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _TextFormField(
                      controller: _rateController,
                      label: 'Rate *',
                      hint: '2500.00',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a rate';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _TextFormField(
                      controller: _distanceController,
                      label: 'Distance (miles)',
                      hint: '920',
                      icon: Icons.straighten,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Route Information Section
              _SectionHeader(
                icon: Icons.route,
                title: 'Route Information',
              ),
              const SizedBox(height: 16),
              _FormCard(
                child: Column(
                  children: [
                    _TextFormField(
                      controller: _originController,
                      label: 'Pickup Location *',
                      hint: 'Chicago, IL 60601',
                      icon: Icons.location_on,
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter pickup location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _DatePicker(
                      label: 'Pickup Date *',
                      icon: Icons.calendar_today,
                      selectedDate: _pickupDate,
                      onDateSelected: (date) {
                        setState(() => _pickupDate = date);
                      },
                    ),
                    const SizedBox(height: 16),
                    _TextFormField(
                      controller: _destinationController,
                      label: 'Delivery Location *',
                      hint: 'Dallas, TX 75201',
                      icon: Icons.flag,
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter delivery location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _DatePicker(
                      label: 'Delivery Date *',
                      icon: Icons.event,
                      selectedDate: _deliveryDate,
                      onDateSelected: (date) {
                        setState(() => _deliveryDate = date);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Assignment Section
              _SectionHeader(
                icon: Icons.person,
                title: 'Assignment',
              ),
              const SizedBox(height: 16),
              _FormCard(
                child: Column(
                  children: [
                    _DropdownField(
                      label: 'Driver',
                      icon: Icons.person,
                      value: _selectedDriver,
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Unassigned')),
                        DropdownMenuItem(value: 'driver1', child: Text('John Smith')),
                        DropdownMenuItem(value: 'driver2', child: Text('Jane Doe')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedDriver = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    _DropdownField(
                      label: 'Status',
                      icon: Icons.info,
                      value: _status,
                      items: const [
                        DropdownMenuItem(
                          value: LoadStatus.pending,
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: LoadStatus.booked,
                          child: Text('Booked'),
                        ),
                        DropdownMenuItem(
                          value: LoadStatus.inTransit,
                          child: Text('In Transit'),
                        ),
                        DropdownMenuItem(
                          value: LoadStatus.delivered,
                          child: Text('Delivered'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _status = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Notes Section
              _SectionHeader(
                icon: Icons.note,
                title: 'Additional Notes',
              ),
              const SizedBox(height: 16),
              _FormCard(
                child: _TextFormField(
                  controller: _notesController,
                  label: 'Notes',
                  hint: 'Add any special instructions or notes...',
                  icon: Icons.edit_note,
                  maxLines: 4,
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.large,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: widget.loadId == null ? 'Create Load' : 'Save Changes',
                      size: AppButtonSize.large,
                      loading: _isLoading,
                      onPressed: _submitForm,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_pickupDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pickup date')),
      );
      return;
    }

    if (_deliveryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery date')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Submit form data to backend
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.sunrisePurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.sunrisePurple,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;

  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.gradientNight,
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _TextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;

  const _TextFormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textGray),
            prefixIcon: Icon(icon, color: AppColors.sunrisePurple),
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
              borderSide: const BorderSide(color: AppColors.sunrisePurple, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.truckRed),
            ),
          ),
        ),
      ],
    );
  }
}

class _DatePicker extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;

  const _DatePicker({
    required this.label,
    required this.icon,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.sunrisePurple,
                        surface: AppColors.asphaltGray,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                onDateSelected(date);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.05),
                border: Border.all(color: AppColors.borderGray),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.sunrisePurple),
                  const SizedBox(width: 12),
                  Text(
                    selectedDate != null
                        ? '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}'
                        : 'Select date',
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedDate != null ? AppColors.white : AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final Function(T?) onChanged;

  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: AppColors.concreteGray,
          style: const TextStyle(color: AppColors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.sunrisePurple),
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
              borderSide: const BorderSide(color: AppColors.sunrisePurple, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
