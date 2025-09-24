  import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:payrent_business/config/theme.dart';

class AddPropertyPage extends StatefulWidget {
  const AddPropertyPage({super.key});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _propertyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  
  String _propertyType = 'Single Family';
  bool _isMultiUnit = false;
  
  List<Map<String, dynamic>> _units = [];
  
  final List<String> _propertyTypes = [
    'Single Family',
    'Apartment',
    'Condo',
    'Townhouse',
    'Duplex',
    'Commercial',
    'Other',
  ];
  
  @override
  void dispose() {
    _propertyNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }
  
  void _addUnit() {
    setState(() {
      _units.add({
        'unitNumber': '',
        'unitType': 'Apartment',
        'bedrooms': 1,
        'bathrooms': 1,
        'rent': 0,
      });
    });
  }
  
  void _removeUnit(int index) {
    setState(() {
      _units.removeAt(index);
    });
  }
  
  void _updateUnit(int index, String field, dynamic value) {
    setState(() {
      _units[index][field] = value;
    });
  }
  
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // In a real app, this would save the property data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Property saved successfully!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Navigate back to the property list
      Navigator.pop(context);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Add Property'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView( physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Type Selection
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Property Type',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Property Type Dropdown
                        DropdownButtonFormField<String>(
                          value: _propertyType,
                          decoration: const InputDecoration(
                            labelText: 'Select Property Type',
                            prefixIcon: Icon(Icons.home_outlined),
                          ),
                          items: _propertyTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              _propertyType = value!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a property type';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Multi-unit Switch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Multi-unit Property',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Switch(
                              value: _isMultiUnit,
                              activeColor: AppTheme.primaryColor,
                              onChanged: (value) {
                                setState(() {
                                  _isMultiUnit = value;
                                  if (value && _units.isEmpty) {
                                    _addUnit(); // Add first unit automatically
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Property Details
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Property Details',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Property Name
                        TextFormField(
                          controller: _propertyNameController,
                          decoration: const InputDecoration(
                            labelText: 'Property Name',
                            prefixIcon: Icon(Icons.business_outlined),
                            hintText: 'e.g., Serene Apartments',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a property name';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Address
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Street Address',
                            prefixIcon: Icon(Icons.location_on_outlined),
                            hintText: 'e.g., 123 Main St',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the street address';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // City, State, Zip
                        Row(
                          children: [
                            // City
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _cityController,
                                decoration: const InputDecoration(
                                  labelText: 'City',
                                  hintText: 'e.g., New York',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // State
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _stateController,
                                decoration: const InputDecoration(
                                  labelText: 'State',
                                  hintText: 'e.g., NY',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Zip
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _zipController,
                                decoration: const InputDecoration(
                                  labelText: 'Zip',
                                  hintText: 'e.g., 10001',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Property Images
              const SizedBox(height: 16),
              
              FadeInDown(
                duration: const Duration(milliseconds: 700),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Property Images',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Image Upload Box
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to upload property images',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'PNG, JPG or JPEG (max. 5MB)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Unit Details (for multi-unit properties)
              if (_isMultiUnit) ...[
                const SizedBox(height: 16),
                
                FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Unit Details',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Add Unit'),
                                onPressed: _addUnit,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // List of Units
                          ..._units.asMap().entries.map((entry) {
                            int index = entry.key;
                            Map<String, dynamic> unit = entry.value;
                            
                            return _buildUnitForm(index, unit);
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              
              // If not multi-unit, ask for rent
              if (!_isMultiUnit) ...[
                const SizedBox(height: 16),
                
                FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rent Details',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Rent
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Monthly Rent',
                              prefixIcon: Icon(Icons.attach_money_outlined),
                              hintText: 'e.g., 1500',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the monthly rent';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Submit Button
              FadeInUp(
                duration: const Duration(milliseconds: 900),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppTheme.primaryGradient,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        alignment: Alignment.center,
                        child: Text(
                          'Save Property',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildUnitForm(int index, Map<String, dynamic> unit) {
    final List<String> unitTypes = [
      'Apartment',
      'Studio',
      'Office',
      'Shop',
      'Other',
    ];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unit header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Unit ${index + 1}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_units.length > 1)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.errorColor,
                  ),
                  onPressed: () => _removeUnit(index),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Unit Number
          TextFormField(
            initialValue: unit['unitNumber'],
            decoration: const InputDecoration(
              labelText: 'Unit Number',
              prefixIcon: Icon(Icons.tag_outlined),
              hintText: 'e.g., 101',
            ),
            onChanged: (value) => _updateUnit(index, 'unitNumber', value),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter unit number';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Unit Type
          DropdownButtonFormField<String>(
            value: unit['unitType'],
            decoration: const InputDecoration(
              labelText: 'Unit Type',
              prefixIcon: Icon(Icons.apartment_outlined),
            ),
            items: unitTypes.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (String? value) {
              _updateUnit(index, 'unitType', value);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select unit type';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Bedrooms and Bathrooms
          Row(
            children: [
              // Bedrooms
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bedrooms',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            if (unit['bedrooms'] > 0) {
                              _updateUnit(index, 'bedrooms', unit['bedrooms'] - 1);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.remove,
                              size: 16,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '${unit['bedrooms']}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            _updateUnit(index, 'bedrooms', unit['bedrooms'] + 1);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.add,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Bathrooms
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bathrooms',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            if (unit['bathrooms'] > 0) {
                              _updateUnit(index, 'bathrooms', unit['bathrooms'] - 1);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.remove,
                              size: 16,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '${unit['bathrooms']}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            _updateUnit(index, 'bathrooms', unit['bathrooms'] + 1);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.add,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Unit Rent
          TextFormField(
            initialValue: unit['rent'].toString(),
            decoration: const InputDecoration(
              labelText: 'Monthly Rent',
              prefixIcon: Icon(Icons.attach_money_outlined),
              hintText: 'e.g., 1500',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) => _updateUnit(index, 'rent', int.tryParse(value) ?? 0),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the monthly rent';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}