import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../../utils/theme.dart';

class RateConfirmationForm extends StatefulWidget {
  const RateConfirmationForm({super.key});

  @override
  State<RateConfirmationForm> createState() => _RateConfirmationFormState();
}

class _RateConfirmationFormState extends State<RateConfirmationForm> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Confirmation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveForm,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePDF,
          ),
        ],
      ),
      body: FormBuilder(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Load Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Load Information', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'load_number',
                      decoration: const InputDecoration(labelText: 'Load Number *'),
                      validator: FormBuilderValidators.required(),
                    ),
                    const SizedBox(height: 12),
                    FormBuilderDateTimePicker(
                      name: 'pickup_date',
                      decoration: const InputDecoration(labelText: 'Pickup Date *'),
                      inputType: InputType.both,
                      validator: FormBuilderValidators.required(),
                    ),
                    const SizedBox(height: 12),
                    FormBuilderDateTimePicker(
                      name: 'delivery_date',
                      decoration: const InputDecoration(labelText: 'Delivery Date *'),
                      inputType: InputType.both,
                      validator: FormBuilderValidators.required(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Shipper Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Shipper Information', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'shipper_name',
                      decoration: const InputDecoration(labelText: 'Shipper Name *'),
                      validator: FormBuilderValidators.required(),
                    ),
                    const SizedBox(height: 12),
                    FormBuilderTextField(
                      name: 'shipper_address',
                      decoration: const InputDecoration(labelText: 'Shipper Address *'),
                      validator: FormBuilderValidators.required(),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    FormBuilderTextField(
                      name: 'shipper_phone',
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Consignee Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Consignee Information', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'consignee_name',
                      decoration: const InputDecoration(labelText: 'Consignee Name *'),
                      validator: FormBuilderValidators.required(),
                    ),
                    const SizedBox(height: 12),
                    FormBuilderTextField(
                      name: 'consignee_address',
                      decoration: const InputDecoration(labelText: 'Consignee Address *'),
                      validator: FormBuilderValidators.required(),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    FormBuilderTextField(
                      name: 'consignee_phone',
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Rate & Payment
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rate & Payment', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'rate',
                      decoration: const InputDecoration(
                        labelText: 'Rate Amount *',
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.numeric(),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    FormBuilderDropdown(
                      name: 'payment_terms',
                      decoration: const InputDecoration(labelText: 'Payment Terms *'),
                      validator: FormBuilderValidators.required(),
                      items: const [
                        DropdownMenuItem(value: 'quick_pay', child: Text('Quick Pay')),
                        DropdownMenuItem(value: 'net_15', child: Text('Net 15')),
                        DropdownMenuItem(value: 'net_30', child: Text('Net 30')),
                        DropdownMenuItem(value: 'net_45', child: Text('Net 45')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FormBuilderTextField(
                      name: 'notes',
                      decoration: const InputDecoration(labelText: 'Special Instructions'),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cargo Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cargo Details', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: 'commodity',
                      decoration: const InputDecoration(labelText: 'Commodity *'),
                      validator: FormBuilderValidators.required(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'weight',
                            decoration: const InputDecoration(
                              labelText: 'Weight *',
                              suffixText: 'lbs',
                            ),
                            keyboardType: TextInputType.number,
                            validator: FormBuilderValidators.required(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'pieces',
                            decoration: const InputDecoration(labelText: 'Pieces'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveForm() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      // Save to database
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rate Confirmation saved successfully')),
      );
    }
  }

  void _generatePDF() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      // Generate PDF
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF...')),
      );
    }
  }
}
