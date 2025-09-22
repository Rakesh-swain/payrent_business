import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:payrent_business/config/theme.dart';

class AddTenantPage extends StatefulWidget {
  final String? propertyId; // Optional property ID if coming from property details
  
  const AddTenantPage({super.key, this.propertyId});

  @override
  State<AddTenantPage> createState() => _AddTenantPageState();
}

class _AddTenantPageState extends State<AddTenantPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rentAmountController = TextEditingController();
  
  DateTime? _leaseStartDate;
  DateTime? _leaseEndDate;
  String? _selectedPropertyId;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _properties = [];
  
  @override
  void initState() {
    super.initState();
    
    // Initialize with property ID if provided
    if (widget.propertyId != null) {
      _selectedPropertyId = widget.propertyId;
    }
    
    // Fetch properties (simulate API call)
    _fetchProperties();
  }
  
  Future<void> _fetchProperties() async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Sample data
    setState(() {
      _properties = [
        {
          'id': '1',
          'title': 'Modern Apartment in Downtown',
          'address': '123 Main St, New York, NY 10001',
          'rent': 2200,
        },
        {
          'id': '2',
          'title': 'Cozy Studio near Park',
          'address': '456 Elm St, New York, NY 10002',
          'rent': 1800,
        },
        {
          'id': '3',
          'title': 'Luxury Condo with View',
          'address': '789 Oak St, New York, NY 10003',
          'rent': 3500,
        },
        {
          'id': '4',
          'title': '2-Bedroom Townhouse',
          'address': '101 Pine St, New York, NY 10004',
          'rent': 2800,
        },
        {
          'id': '5',
          'title': 'Penthouse Apartment',
          'address': '202 Cedar St, New York, NY 10005',
          'rent': 4200,
        },
      ];
      
      // If property ID is provided, set rent amount from the property
      if (widget.propertyId != null) {
        final property = _properties.firstWhere(
          (p) => p['id'] == widget.propertyId,
          orElse: () => {'rent': 0},
        );
        
        _rentAmountController.text = property['rent'].toString();
      }
    });
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _rentAmountController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }
  
  Future<void> _selectLeaseStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _leaseStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _leaseStartDate) {
      setState(() {
        _leaseStartDate = picked;
        
        // If end date is before start date, reset it
        if (_leaseEndDate != null && _leaseEndDate!.isBefore(_leaseStartDate!)) {
          _leaseEndDate = null;
        }
      });
    }
  }
  
  Future<void> _selectLeaseEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _leaseEndDate ?? _leaseStartDate ?? DateTime.now(),
      firstDate: _leaseStartDate ?? DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _leaseEndDate) {
      setState(() {
        _leaseEndDate = picked;
      });
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedPropertyId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a property'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
      
      if (_leaseStartDate == null || _leaseEndDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select lease start and end dates'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
      
      setState(() {
        _isLoading = true;
      });
      
      // TODO: Implement tenant creation logic
      
      // Simulate API call
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tenant added successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Navigate back
        Navigator.pop(context);
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Add Tenant'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView( physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tenant Profile
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
                          'Tenant Information',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                  backgroundImage: _profileImage != null
                                      ? FileImage(_profileImage!) as ImageProvider
                                      : const AssetImage('assets/default_avatar.png'),
                                  child: _profileImage == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: AppTheme.primaryColor,
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter tenant name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter email address';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter phone number';
                            }
                            if (value.length < 10) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Property Assignment
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
                          'Property Assignment',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedPropertyId,
                          decoration: const InputDecoration(
                            labelText: 'Select Property',
                            prefixIcon: Icon(Icons.home_outlined),
                            hintText: 'Choose a property',
                          ),
                          items: _properties.map((property) {
                            return DropdownMenuItem<String>(
                              value: property['id'].toString(),
                              child: Text(
                                property['title'],
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPropertyId = value;
                              
                              // Update rent amount from selected property
                              if (value != null) {
                                final property = _properties.firstWhere(
                                  (p) => p['id'].toString() == value,
                                  orElse: () => {'rent': 0},
                                );
                                
                                _rentAmountController.text = property['rent'].toString();
                              }
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a property';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _rentAmountController,
                          decoration: const InputDecoration(
                            labelText: 'Monthly Rent Amount (\$)',
                            prefixIcon: Icon(Icons.attach_money_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter rent amount';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Lease Information
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
                          'Lease Information',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _selectLeaseStartDate,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Lease Start Date',
                              prefixIcon: const Icon(Icons.calendar_today_outlined),
                              hintText: 'Select start date',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _leaseStartDate != null
                                  ? _formatDate(_leaseStartDate!)
                                  : 'Select start date',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: _leaseStartDate != null
                                    ? AppTheme.textPrimary
                                    : AppTheme.textLight,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _selectLeaseEndDate,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Lease End Date',
                              prefixIcon: const Icon(Icons.calendar_today_outlined),
                              hintText: 'Select end date',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _leaseEndDate != null
                                  ? _formatDate(_leaseEndDate!)
                                  : 'Select end date',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: _leaseEndDate != null
                                    ? AppTheme.textPrimary
                                    : AppTheme.textLight,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Submit Button
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
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
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Add Tenant',
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
            ],
          ),
        ),
      ),
    );
  }
}