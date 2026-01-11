import 'package:flutter/material.dart';
import 'dart:async';

/// Fuel Entry Screen for logging fuel purchases
class FuelEntryScreen extends StatefulWidget {
  const FuelEntryScreen({super.key});

  @override
  State<FuelEntryScreen> createState() => _FuelEntryScreenState();
}

class _FuelEntryScreenState extends State<FuelEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gallonsController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _mileageController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedFuelType = 'Regular';
  bool _isSaving = false;

  final List<String> _fuelTypes = ['Regular', 'Premium', 'Diesel'];

  @override
  void dispose() {
    _gallonsController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Fuel Entry'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveEntry,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateSection(),
              const SizedBox(height: 24),
              _buildFuelDetailsSection(),
              const SizedBox(height: 24),
              _buildLocationSection(),
              const SizedBox(height: 24),
              _buildMileageSection(),
              const SizedBox(height: 32),
              _buildSummarySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                style: const TextStyle(fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                alignment: Alignment.centerLeft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelDetailsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fuel Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _gallonsController,
                    decoration: const InputDecoration(
                      labelText: 'Gallons',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_gas_station),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter gallons';
                      }
                      final gallons = double.tryParse(value);
                      if (gallons == null || gallons <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price per Gallon',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter price';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedFuelType,
              decoration: const InputDecoration(
                labelText: 'Fuel Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.oil_barrel),
              ),
              items: _fuelTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedFuelType = value!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Station Name/Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
                hintText: 'e.g., Shell - Main St',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter location';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMileageSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mileage',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mileageController,
              decoration: const InputDecoration(
                labelText: 'Current Mileage',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.speed),
                hintText: 'e.g., 125430',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter mileage';
                }
                final mileage = int.tryParse(value);
                if (mileage == null || mileage <= 0) {
                  return 'Please enter a valid mileage';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    final gallons = double.tryParse(_gallonsController.text) ?? 0;
    final pricePerGallon = double.tryParse(_priceController.text) ?? 0;
    final totalCost = gallons * pricePerGallon;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Total Cost', '\$${totalCost.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildSummaryRow('Fuel Type', _selectedFuelType),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Date',
              '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
            ),
            if (_locationController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildSummaryRow('Location', _locationController.text),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fuel entry saved successfully!')),
      );

      Navigator.of(context).pop();
    }
  }
}

