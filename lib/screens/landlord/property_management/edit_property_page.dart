// lib/screens/landlord/property_management/edit_property_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/models/property_model.dart';
import 'package:payrent_business/widgets/common/app_loading_indicator.dart';

class EditPropertyPage extends StatefulWidget {
  final String propertyId;
  final PropertyModel property;
  
  const EditPropertyPage({
    Key? key,
    required this.propertyId,
    required this.property,
  }) : super(key: key);

  @override
  _EditPropertyPageState createState() => _EditPropertyPageState();
}

class _EditPropertyPageState extends State<EditPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Text controllers for property fields
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipCodeController;
  late TextEditingController _descriptionController;
  
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
  late bool _isMultiUnit;
  
  @override
  void initState() {
    super.initState();
    // Initialize controllers with property data
    _nameController = TextEditingController(text: widget.property.name);
    _addressController = TextEditingController(text: widget.property.address);
    _cityController = TextEditingController(text: widget.property.city);
    _stateController = TextEditingController(text: widget.property.state);
    _zipCodeController = TextEditingController(text: widget.property.zipCode);
    _descriptionController = TextEditingController(text: widget.property.description ?? '');
    
    _selectedPropertyType = widget.property.type;
    _isMultiUnit = widget.property.isMultiUnit;
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
  
  Future<void> _updateProperty() async {
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
        
        // Create updated property data
        final updatedProperty = {
          'name': _nameController.text,
          'address': _addressController.text,
          'city': _cityController.text,
          'state': _stateController.text,
          'zipCode': _zipCodeController.text,
          'type': _selectedPropertyType,
          'isMultiUnit': _isMultiUnit,
          'description': _descriptionController.text,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        // Update in Firestore
        await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('properties')
          .doc(widget.propertyId)
          .update(updatedProperty);
        
        setState(() {
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property updated successfully')),
        );

        // Return true to indicate successful update
        Navigator.pop(context, true);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating property: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text('Edit Property', style: GoogleFonts.poppins()),
        elevation: 0,
        actions: [
          TextButton.icon(
            icon: Icon(Icons.save_outlined),
            label: Text('Save'),
            onPressed: _updateProperty,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: AppLoadingIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property Details Section
                    _buildSectionHeader('Property Details'),
                    
                    FadeInUp(
                      duration: Duration(milliseconds: 300),
                      child: _buildCard(
                        child: Column(
                          children: [
                            // Property Name
                            TextFormField(
                              controller: _nameController,
                              decoration: _inputDecoration('Property Name'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter property name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),
                            
                            // Property Type Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedPropertyType,
                              decoration: _inputDecoration('Property Type'),
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
                            
                            // Multi-Unit Toggle
                            SwitchListTile(
                              title: Text(
                                'Multi-Unit Property',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                'Toggle on if this property has multiple units',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              value: _isMultiUnit,
                              activeColor: AppTheme.primaryColor,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (bool value) {
                                // Show warning if changing from multi to single and there are multiple units
                                if (widget.property.isMultiUnit && 
                                    !value && 
                                    widget.property.units.length > 1) {
                                  _showMultiUnitWarning();
                                } else {
                                  setState(() {
                                    _isMultiUnit = value;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16.0),
                            
                            // Description
                            TextFormField(
                              controller: _descriptionController,
                              decoration: _inputDecoration('Description (Optional)')
                                .copyWith(
                                  alignLabelWithHint: true,
                                ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24.0),
                    
                    // Address Section
                    _buildSectionHeader('Address'),
                    
                    FadeInUp(
                      duration: Duration(milliseconds: 400),
                      child: _buildCard(
                        child: Column(
                          children: [
                            // Property Address
                            TextFormField(
                              controller: _addressController,
                              decoration: _inputDecoration('Street Address'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter street address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),
                            
                            // City
                            TextFormField(
                              controller: _cityController,
                              decoration: _inputDecoration('City'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter city';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),
                            
                            // State and Zip Row
                            Row(
                              children: [
                                // State
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _stateController,
                                    decoration: _inputDecoration('State'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter state';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16.0),
                                // Zip Code
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _zipCodeController,
                                    decoration: _inputDecoration('Zip Code'),
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
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24.0),
                    
                    // Units Management Section (future enhancement)
                    _buildSectionHeader('Units Management'),
                    
                    FadeInUp(
                      duration: Duration(milliseconds: 500),
                      child: _buildCard(
                        child: Column(
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    'This property has ${widget.property.units.length} unit(s)',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'To manage units, please return to the property details page',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.pop(context); // Go back to details page
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    ),
                                    child: Text('Return to Details'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32.0),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateProperty,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: AppLoadingIndicator(size: 28),
                            )
                          : Text(
                              'Save Changes',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
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
  
  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
  
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      labelStyle: GoogleFonts.poppins(
        color: Colors.grey[700],
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: Colors.white,
    );
  }
  
  void _showMultiUnitWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Warning', style: GoogleFonts.poppins()),
        content: Text(
          'This property has multiple units. Changing to a single unit property may affect existing units and tenants.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isMultiUnit = false;
              });
            },
            child: Text('Continue', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}