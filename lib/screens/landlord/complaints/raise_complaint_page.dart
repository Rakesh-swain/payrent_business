import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:payrent_business/config/theme.dart';

class RaiseComplaintPage extends StatefulWidget {
  final String paymentId;
  final Map<String, dynamic> paymentData;

  const RaiseComplaintPage({
    Key? key,
    required this.paymentId,
    required this.paymentData,
  }) : super(key: key);

  @override
  State<RaiseComplaintPage> createState() => _RaiseComplaintPageState();
}

class _RaiseComplaintPageState extends State<RaiseComplaintPage> {
  final TextEditingController _complaintController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isSubmitting = false;
  String _selectedPriority = 'Medium';
  final List<String> _priorities = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void initState() {
    super.initState();
    _loadPaymentInfo();
  }

  @override
  void dispose() {
    _complaintController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  void _loadPaymentInfo() {
    // Pre-fill subject with payment information
    _loadTenantAndPropertyInfo();
  }

  Future<void> _loadTenantAndPropertyInfo() async {
    try {
      final tenantId = widget.paymentData['tenant_id'] ?? '';
      final propertyId = widget.paymentData['property_id'] ?? '';
      final unitId = widget.paymentData['unit_id'] ?? '';
      final amount = (widget.paymentData['amount'] ?? 0.0).toDouble();
      
      // Get tenant name
      final tenantDoc = await _firestore.collection('tenants').doc(tenantId).get();
      final tenantName = tenantDoc.exists 
          ? (tenantDoc.data()?['full_name'] ?? 'Unknown Tenant')
          : 'Unknown Tenant';
      
      // Get property and unit name
      final propertyDoc = await _firestore.collection('properties').doc(propertyId).get();
      String propertyUnitName = 'Unknown Property';
      if (propertyDoc.exists) {
        final propertyData = propertyDoc.data()!;
        final propertyName = propertyData['name'] ?? 'Unknown Property';
        final units = propertyData['units'] as List<dynamic>? ?? [];
        final unit = units.firstWhere(
          (u) => u['id'] == unitId,
          orElse: () => {'unit_name': 'Unknown Unit'},
        );
        final unitName = unit['unit_name'] ?? 'Unknown Unit';
        propertyUnitName = '$propertyName - $unitName';
      }

      // Pre-fill subject
      setState(() {
        _subjectController.text = 'Payment Issue - $tenantName - $propertyUnitName (OMR ${amount.toStringAsFixed(2)})';
      });

      // Pre-fill complaint template
      final dueDate = (widget.paymentData['due_date'] as Timestamp?)?.toDate();
      final status = widget.paymentData['status'] ?? '';
      final reason = widget.paymentData['reason'] ?? '';
      
      String complaintTemplate = '''Dear Team,

I am writing to raise a complaint regarding an overdue/failed payment for the following details:

Tenant: $tenantName
Property: $propertyUnitName
Payment Amount: OMR ${amount.toStringAsFixed(2)}
Due Date: ${dueDate != null ? DateFormat('MMM dd, yyyy').format(dueDate) : 'N/A'}
Current Status: ${status.toUpperCase()}''';

      if (reason.isNotEmpty) {
        complaintTemplate += '\nReason: $reason';
      }

      complaintTemplate += '''

Issue Description:
[Please describe the issue in detail]

Request for Action:
[Please specify what action you would like to be taken]

Thank you for your attention to this matter.

Best regards,
[Your Name]''';

      setState(() {
        _complaintController.text = complaintTemplate;
      });

    } catch (e) {
      print('Error loading payment info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 800;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Raise Complaint',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isWeb ? _buildWebLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildWebLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 800),
          child: _buildComplaintForm(),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildComplaintForm(),
    );
  }

  Widget _buildComplaintForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.report_problem,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Complaint',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Describe your issue and we\'ll help resolve it',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Payment Info Card
          _buildPaymentInfoCard(),

          const SizedBox(height: 24),

          // Subject Field
          Text(
            'Subject *',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _subjectController,
            decoration: InputDecoration(
              hintText: 'Brief description of the issue',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: GoogleFonts.poppins(fontSize: 14),
          ),

          const SizedBox(height: 24),

          // Priority Selection
          Text(
            'Priority *',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPriority,
                isExpanded: true,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPriority = newValue!;
                  });
                },
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
                items: _priorities.map<DropdownMenuItem<String>>((String value) {
                  Color priorityColor = _getPriorityColor(value);
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: priorityColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(value),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Complaint Text Editor
          Text(
            'Complaint Details *',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: TextFormField(
              controller: _complaintController,
              maxLines: 12,
              decoration: InputDecoration(
                hintText: 'Describe your complaint in detail...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitComplaint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Submit Complaint',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
    final amount = (widget.paymentData['amount'] ?? 0.0).toDouble();
    final status = widget.paymentData['status'] ?? '';
    final dueDate = (widget.paymentData['due_date'] as Timestamp?)?.toDate();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade50,
            Colors.orange.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Information',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Amount', 'OMR ${amount.toStringAsFixed(2)}'),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Due Date', 
                  dueDate != null ? DateFormat('MMM dd, yyyy').format(dueDate) : 'N/A',
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'failed' ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: status == 'failed' ? Colors.red : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return Colors.blue;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      case 'Critical':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _submitComplaint() async {
    if (_subjectController.text.trim().isEmpty ||
        _complaintController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all required fields',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final landlordId = _auth.currentUser?.uid ?? '';
      final complaintData = {
        'landlord_id': landlordId,
        'payment_id': widget.paymentId,
        'subject': _subjectController.text.trim(),
        'description': _complaintController.text.trim(),
        'priority': _selectedPriority,
        'status': 'created',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'tenant_id': widget.paymentData['tenant_id'],
        'property_id': widget.paymentData['property_id'],
        'unit_id': widget.paymentData['unit_id'],
        'amount': widget.paymentData['amount'],
        'due_date': widget.paymentData['due_date'],
        'payment_status': widget.paymentData['status'],
      };

      await _firestore.collection('complaints').add(complaintData);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Complaint submitted successfully!',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate back
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error submitting complaint: ${e.toString()}',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}