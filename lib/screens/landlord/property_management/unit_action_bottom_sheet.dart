// lib/screens/landlord/property_management/unit_action_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/models/property_model.dart';

class UnitActionBottomSheet extends StatefulWidget {
  final String propertyId;
  final PropertyUnitModel unit;
  final Function onComplete;

  const UnitActionBottomSheet({
    Key? key,
    required this.propertyId,
    required this.unit,
    required this.onComplete,
  }) : super(key: key);

  @override
  _UnitActionBottomSheetState createState() => _UnitActionBottomSheetState();
}

class _UnitActionBottomSheetState extends State<UnitActionBottomSheet> {
  bool _isEditingUnit = false;
  bool _isAssigningTenant = false;
  bool _isLoading = false;

  // Tenant assignment
  List<DocumentSnapshot> _availableTenants = [];
  String? _selectedTenantId;
  DateTime? _leaseStartDate;
  DateTime? _leaseEndDate;

  // Unit editing
  late TextEditingController _unitNumberController;
  late TextEditingController _unitTypeController;
  late TextEditingController _bedroomsController;
  late TextEditingController _bathroomsController;
  late TextEditingController _monthlyRentController;
  late TextEditingController _securityDepositController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with unit data
    _unitNumberController = TextEditingController(text: widget.unit.unitNumber);
    _unitTypeController = TextEditingController(text: widget.unit.unitType);
    _bedroomsController = TextEditingController(
      text: widget.unit.bedrooms.toString(),
    );
    _bathroomsController = TextEditingController(
      text: widget.unit.bathrooms.toString(),
    );
    _monthlyRentController = TextEditingController(
      text: widget.unit.rent.toString(),
    );
    _securityDepositController = TextEditingController(
      text: widget.unit.securityDeposit?.toString() ?? '',
    );
    _notesController = TextEditingController(text: widget.unit.notes ?? '');

    // Load available tenants
    _fetchAvailableTenants();
  }

  @override
  void dispose() {
    _unitNumberController.dispose();
    _unitTypeController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _monthlyRentController.dispose();
    _securityDepositController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchAvailableTenants() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get all tenants for the landlord
      final tenantSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tenants')
          .get();

      setState(() {
        _availableTenants = tenantSnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading tenants: $e')));
    }
  }

  Future<void> _saveUnitChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get current property
      final propertyDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('properties')
          .doc(widget.propertyId)
          .get();

      if (!propertyDoc.exists) {
        throw Exception('Property not found');
      }

      final propertyData = propertyDoc.data() as Map<String, dynamic>;
      final units = List<dynamic>.from(propertyData['units'] ?? []);

      // Find and update the unit
      for (int i = 0; i < units.length; i++) {
        if (units[i]['unitId'] == widget.unit.unitId) {
          units[i] = {
            ...units[i],
            'unitNumber': _unitNumberController.text,
            'unitType': _unitTypeController.text,
            'bedrooms': int.tryParse(_bedroomsController.text) ?? 1,
            'bathrooms': int.tryParse(_bathroomsController.text) ?? 1,
            'rent': int.tryParse(_monthlyRentController.text) ?? 0,
            'securityDeposit': _securityDepositController.text.isNotEmpty
                ? double.tryParse(_securityDepositController.text)
                : null,
            'notes': _notesController.text,
          };
          break;
        }
      }

      // Update property with modified units
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('properties')
          .doc(widget.propertyId)
          .update({'units': units, 'updatedAt': FieldValue.serverTimestamp()});

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unit updated successfully')),
      );

      widget.onComplete();
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating unit: $e')));
    }
  }

  Future<void> _assignTenant() async {
    if (_selectedTenantId == null ||
        _leaseStartDate == null ||
        _leaseEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get tenant data
      final tenantDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tenants')
          .doc(_selectedTenantId)
          .get();

      if (!tenantDoc.exists) {
        throw Exception('Tenant not found');
      }

      // Get current property
      final propertyDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('properties')
          .doc(widget.propertyId)
          .get();

      if (!propertyDoc.exists) {
        throw Exception('Property not found');
      }

      final propertyData = propertyDoc.data() as Map<String, dynamic>;
      final property = PropertyModel.fromFirestore(propertyDoc);
      final units = List<dynamic>.from(propertyData['units'] ?? []);

      // Find and update the unit with tenant ID
      for (int i = 0; i < units.length; i++) {
        if (units[i]['unitId'] == widget.unit.unitId) {
          units[i] = {...units[i], 'tenantId': _selectedTenantId, 'rent': int.tryParse(_monthlyRentController.text) ?? 0};
          break;
        }
      }

      // Update property with tenant-assigned unit
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('properties')
          .doc(widget.propertyId)
          .update({'units': units, 'updatedAt': FieldValue.serverTimestamp()});

      // Create a new tenant properties assignment document (new doc each time)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tenants')
          .doc(_selectedTenantId)
          .collection('properties')
          .add({
            'propertyId': widget.propertyId,
            'propertyName': property.name,
            'propertyAddress': property.address,
            'unitId': widget.unit.unitId,
            'unitNumber': widget.unit.unitNumber,
            'leaseStartDate': Timestamp.fromDate(_leaseStartDate!),
            'leaseEndDate': Timestamp.fromDate(_leaseEndDate!),
            'rentAmount':
                double.tryParse(_monthlyRentController.text) ??
                widget.unit.rent,
            'securityDeposit': _securityDepositController.text.isNotEmpty
                ? double.tryParse(_securityDepositController.text)
                : widget.unit.securityDeposit,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Store lease information in units subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('properties')
          .doc(widget.propertyId)
          .collection('units')
          .doc(widget.unit.unitId)
          .collection('tenants')
          .doc(_selectedTenantId)
          .set({
            'tenantId': _selectedTenantId,
            'startDate': Timestamp.fromDate(_leaseStartDate!),
            'endDate': Timestamp.fromDate(_leaseEndDate!),
            'rentAmount':
                double.tryParse(_monthlyRentController.text) ??
                widget.unit.rent,
            'securityDeposit': _securityDepositController.text.isNotEmpty
                ? double.tryParse(_securityDepositController.text)
                : widget.unit.securityDeposit,
            'createdAt': FieldValue.serverTimestamp(),
          });

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tenant assigned successfully')),
      );

      widget.onComplete();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error assigning tenant: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title and close button
            Row(
              children: [
                Text(
                  _isEditingUnit
                      ? 'Edit Unit'
                      : (_isAssigningTenant ? 'Assign Tenant' : 'Unit Actions'),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            // Divider
            Divider(height: 24),

            if (!_isEditingUnit && !_isAssigningTenant)
              _buildUnitActionOptions()
            else if (_isEditingUnit)
              _buildUnitEditForm()
            else if (_isAssigningTenant)
              _buildTenantAssignForm(),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitActionOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Unit Info
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFF8F9FB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFFF0EEFE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Unit ${widget.unit.unitNumber}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                  Spacer(),
                  Text(
                    widget.unit.tenantId != null ? 'Occupied' : 'Vacant',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: widget.unit.tenantId != null
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoItem('Type', widget.unit.unitType),
                  SizedBox(width: 24),
                  _buildInfoItem(
                    'Size',
                    '${widget.unit.bedrooms} bed, ${widget.unit.bathrooms} bath',
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildInfoItem(
                'Rent',
                'OMR${widget.unit.rent.toStringAsFixed(2)}/mo',
              ),
            ],
          ),
        ),

        SizedBox(height: 24),

        // Action Buttons
        Text(
          'Actions',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.edit,
          label: 'Edit Unit Details',
          color: Colors.blue,
          onTap: () {
            setState(() {
              _isEditingUnit = true;
              _isAssigningTenant = false;
            });
          },
        ),
        SizedBox(height: 8),
        _buildActionButton(
          icon: widget.unit.tenantId != null
              ? Icons.person_off
              : Icons.person_add,
          label: widget.unit.tenantId != null
              ? 'Change Tenant'
              : 'Assign Tenant',
          color: widget.unit.tenantId != null ? Colors.orange : Colors.green,
          onTap: () {
            setState(() {
              _isAssigningTenant = true;
              _isEditingUnit = false;
            });
          },
        ),
        if (widget.unit.tenantId != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _buildActionButton(
              icon: Icons.person_remove,
              label: 'Remove Tenant',
              color: Colors.red,
              onTap: _confirmRemoveTenant,
            ),
          ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            Spacer(),
            Icon(Icons.chevron_right, color: color.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unit Details',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 16),

        // Unit Number
        TextField(
          controller: _unitNumberController,
          decoration: InputDecoration(
            labelText: 'Unit Number/Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        SizedBox(height: 16),

        // Unit Type
        TextField(
          controller: _unitTypeController,
          decoration: InputDecoration(
            labelText: 'Unit Type',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        SizedBox(height: 16),

        // Bedrooms & Bathrooms Row
        Row(
          children: [
            // Bedrooms
            Expanded(
              child: TextField(
                controller: _bedroomsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Bedrooms',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            // Bathrooms
            Expanded(
              child: TextField(
                controller: _bathroomsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Bathrooms',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Rent & Deposit Row
        Row(
          children: [
            // Monthly Rent
            Expanded(
              child: TextField(
                controller: _monthlyRentController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Monthly Rent',
                  prefixText: 'OMR ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            // Security Deposit
            Expanded(
              child: TextField(
                controller: _securityDepositController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Security Deposit',
                  prefixText: 'OMR ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Notes
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Notes (Optional)',
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        SizedBox(height: 24),

        // Save & Cancel Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isEditingUnit = false;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Cancel'),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveUnitChanges,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTenantAssignForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assign Tenant',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 16),

        // Tenant Selection Dropdown
        DropdownButtonFormField<String>(
          value: _selectedTenantId,
          decoration: InputDecoration(
            labelText: 'Select Tenant',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: _availableTenants.map((tenant) {
            final data = tenant.data() as Map<String, dynamic>;
            final name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}';
            final phone = data['phone'] ?? '';

            return DropdownMenuItem<String>(
              value: tenant.id,
              child: SizedBox(
                height: 50,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(width: 10),
                    if (phone.isNotEmpty)
                      Text(
                        "($phone)",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (String? value) {
            setState(() {
              _selectedTenantId = value;
            });
          },
        ),
        SizedBox(height: 16),

        // Date Selection Row
        Row(
          children: [
            // Lease Start Date
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _leaseStartDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );

                  if (date != null) {
                    setState(() {
                      _leaseStartDate = date;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Date',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _leaseStartDate != null
                            ? DateFormat('MMM d, yyyy').format(_leaseStartDate!)
                            : 'Select Date',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            // Lease End Date
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate:
                        _leaseEndDate ??
                        (_leaseStartDate?.add(Duration(days: 365)) ??
                            DateTime.now()),
                    firstDate: _leaseStartDate ?? DateTime.now(),
                    lastDate: DateTime(2100),
                  );

                  if (date != null) {
                    setState(() {
                      _leaseEndDate = date;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Date',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _leaseEndDate != null
                            ? DateFormat('MMM d, yyyy').format(_leaseEndDate!)
                            : 'Select Date',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Rent Amount
        TextField(
          controller: _monthlyRentController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Rent Amount',
            prefixText: '\OMR ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        SizedBox(height: 16),

        // Security Deposit
        TextField(
          controller: _securityDepositController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Security Deposit',
            prefixText: '\OMR ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        SizedBox(height: 24),

        // Save & Cancel Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isAssigningTenant = false;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Cancel'),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_selectedTenantId == null ||
                            _selectedTenantId!.isEmpty) {
                              Get.snackbar('Error', 'Please select a tenant.',backgroundColor: Colors.redAccent,colorText: Colors.white);

                          return;
                        }

                        if (_leaseStartDate == null) {
                          Get.snackbar('Error', 'Please select a lease start date.',backgroundColor: Colors.redAccent,colorText: Colors.white);
                          return;
                        }

                        if (_leaseEndDate == null) {
                          Get.snackbar('Error', 'Please select a lease end date.',backgroundColor: Colors.redAccent,colorText: Colors.white);
                          return;
                        }

                        if (_leaseEndDate!.isBefore(_leaseStartDate!)) {
                          Get.snackbar('Error', 'End date cannot be before start date.',backgroundColor: Colors.redAccent,colorText: Colors.white);
                          return;
                        }

                        // ✅ All validations passed
                        await _assignTenant();
                      },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Assign Tenant',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _confirmRemoveTenant() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Tenant', style: GoogleFonts.poppins()),
        content: Text(
          'Are you sure you want to remove this tenant from the unit?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _removeTenant();
            },
            child: Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _removeTenant() async {
    if (widget.unit.tenantId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get current property
      final propertyDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('properties')
          .doc(widget.propertyId)
          .get();

      if (!propertyDoc.exists) {
        throw Exception('Property not found');
      }

      final propertyData = propertyDoc.data() as Map<String, dynamic>;
      final units = List<dynamic>.from(propertyData['units'] ?? []);

      // Find and update the unit
      for (int i = 0; i < units.length; i++) {
        if (units[i]['unitId'] == widget.unit.unitId) {
          units[i] = {
            ...units[i],
            'tenantId': null, // Remove tenant ID
          };
          break;
        }
      }

      // Update property
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('properties')
          .doc(widget.propertyId)
          .update({'units': units, 'updatedAt': FieldValue.serverTimestamp()});

      // Remove tenant assignments for this property/unit from their properties subcollection
      final propsQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tenants')
          .doc(widget.unit.tenantId)
          .collection('properties')
          .where('propertyId', isEqualTo: widget.propertyId)
          .where('unitId', isEqualTo: widget.unit.unitId)
          .get();
      for (final d in propsQuery.docs) {
        await d.reference.delete();
      }

      // Delete lease info from unit
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('properties')
          .doc(widget.propertyId)
          .collection('units')
          .doc(widget.unit.unitId)
          .collection('tenants')
          .doc(widget.unit.tenantId)
          .delete();

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tenant removed successfully')),
      );

      widget.onComplete();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error removing tenant: $e')));
    }
  }
}
