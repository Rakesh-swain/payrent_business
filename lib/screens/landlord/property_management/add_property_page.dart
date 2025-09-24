import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/models/property_model.dart';


class AddPropertyPage extends StatefulWidget {
  const AddPropertyPage({Key? key}) : super(key: key);

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Text controllers for property fields
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Property type dropdown
  String _selectedPropertyType = 'Single Family';
  final List<String> _propertyTypes = [
    'Single Family',
    'Multi Family',
    'Apartment',
    'Condo',
    'Townhouse',
    'Commercial',
    'Other'
  ];
  
  // Multi-unit toggle
  bool _isMultiUnit = false;
  
  // List of units
  List<PropertyUnitModel> _units = [];
  
  @override
  void initState() {
    super.initState();
    // Add a default unit
    _addUnit();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  // Add a new unit to the list
  void _addUnit() {
    final newUnit = PropertyUnitModel(
      unitNumber: _units.isEmpty ? "Main" : "Unit ${_units.length + 1}",
      unitType: "Standard",
      bedrooms: 1,
      bathrooms: 1.0,
      monthlyRent: 0.0,
    );
    
    setState(() {
      _units.add(newUnit);
    });
  }
  
  // Remove a unit from the list
  void _removeUnit(int index) {
    if (_units.length > 1) {
      setState(() {
        _units.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property must have at least one unit')),
      );
    }
  }
  
  // Update a unit in the list
  void _updateUnit(int index, PropertyUnitModel updatedUnit) {
    setState(() {
      _units[index] = updatedUnit;
    });
  }
  
  // Submit the form
  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get the current user ID
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          throw Exception('User not logged in');
        }
        
        // Create the property model
        final property = PropertyModel(
          name: _nameController.text,
          address: _addressController.text,
          city: _cityController.text,
          state: _stateController.text,
          zipCode: _zipCodeController.text,
          type: _selectedPropertyType,
          isMultiUnit: _isMultiUnit,
          units: _units,
          landlordId: userId,
          description: _descriptionController.text,
        );
        
        // Convert to Firestore data
        final propertyData = property.toFirestore();
        
        // Save to Firestore in users/properties collection
        await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('properties')
          .add(propertyData);
        

        setState(() {
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property added successfully')),
        );

        // Navigate back
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding property: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Add Property', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context)
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Property Details Section
                      _buildSectionTitle('Property Details'),
                      
                      // Property Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Property Name',
                          hintText: 'Enter property name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter property name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      
                      // Property Address
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          hintText: 'Enter property address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter property address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      
                      // Property City
                      TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: 'City',
                          hintText: 'Enter city',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter city';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      
                      // State and Zip Code Row
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _stateController,
                              decoration: InputDecoration(
                                labelText: 'State',
                                hintText: 'Enter state',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter state';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _zipCodeController,
                              decoration: InputDecoration(
                                labelText: 'Zip Code',
                                hintText: 'Enter zip code',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter zip code';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      
                      // Property Type Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedPropertyType,
                        decoration: InputDecoration(
                          labelText: 'Property Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        items: _propertyTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedPropertyType = newValue;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select property type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter property description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24.0),
                      
                      // Multi-Unit Toggle
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Text(
                                'Multi-Unit Property',
                                style: GoogleFonts.poppins(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: _isMultiUnit,
                                onChanged: (bool value) {
                                  setState(() {
                                    _isMultiUnit = value;
                                    // Reset units when toggling
                                    _units.clear();
                                    _addUnit(); // Add a default unit
                                  });
                                },
                                activeColor: AppTheme.primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      
                      // Units Section
                      _buildSectionTitle('Units'),
                      
                      // Units List
                      ..._buildUnitsList(),
                      
                      // Add Unit Button
                      if (_isMultiUnit) ...[
                        const SizedBox(height: 16.0),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _addUnit,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Unit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 32.0),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Save Property',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: 24.0),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
  
  // Build section title
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
  
  // Build units list
  List<Widget> _buildUnitsList() {
    final widgets = <Widget>[];
    
    for (var i = 0; i < _units.length; i++) {
      final unit = _units[i];
      
      widgets.add(
        FadeInUp(
          duration: Duration(milliseconds: 300 + (i * 100)),
          child: Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(color: Colors.grey[300]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Unit ${i + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_isMultiUnit)
                        IconButton(
                          onPressed: () => _removeUnit(i),
                          icon: const Icon(Icons.delete),
                          color: Colors.red,
                        ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12.0),
                  
                  // Unit Number
                  TextFormField(
                    initialValue: unit.unitNumber,
                    decoration: InputDecoration(
                      labelText: 'Unit Number/Name',
                      hintText: 'e.g. 101, A, Basement',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter unit number';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _updateUnit(
                        i,
                        unit.copyWith(unitNumber: value),
                      );
                    },
                  ),
                  const SizedBox(height: 12.0),
                  
                  // Unit Type
                  TextFormField(
                    initialValue: unit.unitType,
                    decoration: InputDecoration(
                      labelText: 'Unit Type',
                      hintText: 'e.g. Studio, 1BR, 2BR',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    onChanged: (value) {
                      _updateUnit(
                        i,
                        unit.copyWith(unitType: value),
                      );
                    },
                  ),
                  const SizedBox(height: 12.0),
                  
                  // Bedrooms & Bathrooms
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: unit.bedrooms.toString(),
                          decoration: InputDecoration(
                            labelText: 'Bedrooms',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _updateUnit(
                              i,
                              unit.copyWith(bedrooms: int.tryParse(value) ?? 0),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: TextFormField(
                          initialValue: unit.bathrooms.toString(),
                          decoration: InputDecoration(
                            labelText: 'Bathrooms',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _updateUnit(
                              i,
                              unit.copyWith(bathrooms: double.tryParse(value) ?? 0.0),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  
                  // Monthly Rent & Security Deposit
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: unit.monthlyRent.toString(),
                          decoration: InputDecoration(
                            labelText: 'Monthly Rent',
                            prefixText: '\$',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _updateUnit(
                              i,
                              unit.copyWith(monthlyRent: double.tryParse(value) ?? 0.0),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: TextFormField(
                          initialValue: unit.securityDeposit?.toString() ?? '',
                          decoration: InputDecoration(
                            labelText: 'Security Deposit',
                            prefixText: '\$',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _updateUnit(
                              i,
                              unit.copyWith(securityDeposit: value.isNotEmpty ? double.tryParse(value) : null),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  
                  // Notes
                  TextFormField(
                    initialValue: unit.notes ?? '',
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Any additional information about this unit',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    maxLines: 2,
                    onChanged: (value) {
                      _updateUnit(
                        i,
                        unit.copyWith(notes: value),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return widgets;
  }
}