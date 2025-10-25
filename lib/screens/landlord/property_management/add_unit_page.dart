import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/models/property_model.dart';

class AddUnitPage extends StatefulWidget {
  final String propertyId;

  const AddUnitPage({super.key, required this.propertyId});

  @override
  State<AddUnitPage> createState() => _AddUnitPageState();
}

class _AddUnitPageState extends State<AddUnitPage> {
  List<PropertyUnitModel> _units = [];
  final List<TextEditingController> _unitNumberControllers = [];
  final List<TextEditingController> _unitTypeControllers = [];
  final List<TextEditingController> _bedroomsControllers = [];
  final List<TextEditingController> _bathroomsControllers = [];
  final List<TextEditingController> _rentControllers = [];
  final List<TextEditingController> _securityControllers = [];

  @override
  void initState() {
    super.initState();
    _addUnit(); // Add default first unit
  }

  @override
  void dispose() {
    for (var c in _unitNumberControllers) c.dispose();
    for (var c in _unitTypeControllers) c.dispose();
    for (var c in _bedroomsControllers) c.dispose();
    for (var c in _bathroomsControllers) c.dispose();
    for (var c in _rentControllers) c.dispose();
    for (var c in _securityControllers) c.dispose();
    super.dispose();
  }

  void _addUnit() {
    final newUnit = PropertyUnitModel(
      unitNumber: 'Unit ${_units.length + 1}',
      unitType: 'Standard',
      bedrooms: 1,
      bathrooms: 1,
      rent: 0,
      paymentFrequency: 'Monthly',
    );

    setState(() {
      _units.add(newUnit);
      _unitNumberControllers.add(TextEditingController(text: newUnit.unitNumber));
      _unitTypeControllers.add(TextEditingController(text: newUnit.unitType));
      _bedroomsControllers.add(TextEditingController(text: newUnit.bedrooms.toString()));
      _bathroomsControllers.add(TextEditingController(text: newUnit.bathrooms.toString()));
      _rentControllers.add(TextEditingController(text: newUnit.rent.toString()));
      _securityControllers.add(TextEditingController(text: newUnit.securityDeposit?.toString() ?? ''));
    });
  }

  void _removeUnit(int index) {
    if (_units.length > 1) {
      setState(() {
        _units.removeAt(index);
        _unitNumberControllers.removeAt(index).dispose();
        _unitTypeControllers.removeAt(index).dispose();
        _bedroomsControllers.removeAt(index).dispose();
        _bathroomsControllers.removeAt(index).dispose();
        _rentControllers.removeAt(index).dispose();
        _securityControllers.removeAt(index).dispose();
      });
    }
  }

  Future<void> _saveUnits() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final propertyRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('properties')
          .doc(widget.propertyId);

      final propertySnapshot = await propertyRef.get();
      if (!propertySnapshot.exists) throw Exception('Property not found');

      // Update unit values from controllers
      for (int i = 0; i < _units.length; i++) {
        _units[i] = _units[i].copyWith(
          unitNumber: _unitNumberControllers[i].text,
          unitType: _unitTypeControllers[i].text,
          bedrooms: int.tryParse(_bedroomsControllers[i].text) ?? 1,
          bathrooms: int.tryParse(_bathroomsControllers[i].text) ?? 1,
          rent: int.tryParse(_rentControllers[i].text) ?? 0,
          securityDeposit: _securityControllers[i].text.isNotEmpty
              ? int.tryParse(_securityControllers[i].text)
              : null,
        );
      }

      final currentUnits = List<Map<String, dynamic>>.from(
        propertySnapshot['units'] ?? [],
      );

      final newUnits = _units.map((e) => e.toMap()).toList();

      await propertyRef.update({
        'units': [...currentUnits, ...newUnits],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Units added successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding units: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Units'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: _saveUnits,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                backgroundColor: const Color(0xFF4F287D),
              ),
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ...List.generate(_units.length, (index) {
              final unit = _units[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Unit ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeUnit(index),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _unitNumberControllers[index],
                        decoration: const InputDecoration(labelText: 'Unit Number/Name', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _unitTypeControllers[index],
                        decoration: const InputDecoration(labelText: 'Unit Type', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _bedroomsControllers[index],
                              decoration: const InputDecoration(labelText: 'Bedrooms', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _bathroomsControllers[index],
                              decoration: const InputDecoration(labelText: 'Bathrooms', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _rentControllers[index],
                              decoration: const InputDecoration(labelText: 'Rent', prefixText: 'OMR ', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _securityControllers[index],
                              decoration: const InputDecoration(labelText: 'Security Deposit', prefixText: 'OMR ', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            // Add Unit button below the list
            SizedBox(
              // width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addUnit,
                icon: const Icon(Icons.add),
                label: const Text('Add Another Unit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16,horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
