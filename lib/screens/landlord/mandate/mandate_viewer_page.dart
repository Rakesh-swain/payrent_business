import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/models/property_model.dart';
import 'package:payrent_business/models/account_information_model.dart';
import 'package:payrent_business/models/mandate_model.dart';

class MandatePreviewPage extends StatefulWidget {
  final PropertyUnitModel unit;
  final DocumentSnapshot tenantDoc;
  final AccountInformation landlordAccountInfo;
  final String propertyId;
  final String frequency;
  final DateTime startDate;
  final DateTime endDate;
  final int totalInstallments;
  final int customAmount;

  const MandatePreviewPage({
    Key? key,
    required this.unit,
    required this.tenantDoc,
    required this.landlordAccountInfo,
    required this.propertyId,
    required this.frequency,
    required this.startDate,
    required this.endDate,
    required this.totalInstallments,
    required this.customAmount,
  }) : super(key: key);

  @override
  _MandatePreviewPageState createState() => _MandatePreviewPageState();
}

class _MandatePreviewPageState extends State<MandatePreviewPage> {
  String _selectedPaymentMethod = 'Bank Transfer';
  bool _isCreating = false;
  
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'name': 'Bank Transfer',
      'icon': Icons.account_balance,
      'description': 'Direct bank-to-bank transfer',
      'color': Colors.blue,
    },
    {
      'name': 'Mobile Money',
      'icon': Icons.phone_android,
      'description': 'Mobile wallet payment',
      'color': Colors.green,
    },
    {
      'name': 'Card Payment',
      'icon': Icons.credit_card,
      'description': 'Credit or debit card',
      'color': Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final tenantData = widget.tenantDoc.data() as Map<String, dynamic>;
    final totalAmount = widget.customAmount * widget.totalInstallments;
    
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text(
          'Mandate Preview',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Header
            FadeInUp(
              duration: Duration(milliseconds: 300),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.green.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.check_circle, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mandate Ready to Create',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Review details and select payment method',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Mandate Summary Card
            FadeInUp(
              duration: Duration(milliseconds: 400),
              child: _buildSummaryCard(tenantData, totalAmount),
            ),
            
            SizedBox(height: 16),
            
            // Payment Method Selection
            FadeInUp(
              duration: Duration(milliseconds: 500),
              child: _buildPaymentMethodCard(),
            ),
            
            SizedBox(height: 16),
            
            // Collection Summary
            FadeInUp(
              duration: Duration(milliseconds: 600),
              child: _buildCollectionSummaryCard(totalAmount),
            ),
            
            SizedBox(height: 32),
            
            // Action Buttons
            FadeInUp(
              duration: Duration(milliseconds: 700),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isCreating ? (){}: _createMandate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isCreating
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Creating Mandate...'),
                              ],
                            )
                          : Text(
                              'Create Mandate',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _sharePaymentLink,
                      icon: Icon(Icons.share),
                      label: Text('Share Payment Link'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryCard(Map<String, dynamic> tenantData, int totalAmount) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.receipt_long, color: AppTheme.primaryColor, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  'Mandate Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Property & Unit Info
            _buildSummaryRow('Property Unit', 'Unit ${widget.unit.unitNumber}'),
            _buildSummaryRow('Tenant', '${tenantData['firstName']} ${tenantData['lastName']}'),
            _buildSummaryRow('Rent Amount', '\$${widget.customAmount}/payment'),
            _buildSummaryRow('Payment Frequency', widget.frequency),
            _buildSummaryRow('Start Date', DateFormat('MMM d, yyyy').format(widget.startDate)),
            _buildSummaryRow('End Date', DateFormat('MMM d, yyyy').format(widget.endDate)),
            _buildSummaryRow('Total Payments', '${widget.totalInstallments} payments'),
            
            Divider(height: 24),
            
            _buildSummaryRow(
              'Total Collection Amount', 
              '\$${totalAmount.toStringAsFixed(2)}',
              isHighlighted: true,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
                color: isHighlighted ? Colors.green : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentMethodCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.payment, color: Colors.blue, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  'Select Payment Method',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            Column(
              children: _paymentMethods.map((method) {
                final isSelected = method['name'] == _selectedPaymentMethod;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = method['name'];
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? method['color'].withOpacity(0.1) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? method['color'] : Colors.grey[200]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: method['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            method['icon'],
                            color: method['color'],
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method['name'],
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                method['description'],
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: method['color'],
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCollectionSummaryCard(int totalAmount) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.green.withOpacity(0.1), Colors.blue.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.account_balance_wallet, color: Colors.green, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  'Collection Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Collection',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '\$${totalAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${widget.totalInstallments}',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        'Installments',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payments will be collected ${widget.frequency.toLowerCase()} starting ${DateFormat('MMM d').format(widget.startDate)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _createMandate() async {
    setState(() {
      _isCreating = true;
    });
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');
      
      final tenantData = widget.tenantDoc.data() as Map<String, dynamic>;
      
      final mandate = MandateModel(
        landlordId: userId,
        tenantId: widget.tenantDoc.id,
        propertyId: widget.propertyId,
        unitId: widget.unit.unitId,
        landlordAccountHolderName: widget.landlordAccountInfo.accountHolderName,
        landlordAccountNumber: widget.landlordAccountInfo.accountNumber,
        landlordIdType: widget.landlordAccountInfo.idType.value,
        landlordIdNumber: widget.landlordAccountInfo.idNumber,
        landlordBankBic: widget.landlordAccountInfo.bankBic,
        landlordBranchCode: widget.landlordAccountInfo.branchCode,
        tenantAccountHolderName: tenantData['db_account_holder_name'],
        tenantAccountNumber: tenantData['db_account_number'],
        tenantIdType: tenantData['db_id_type'],
        tenantIdNumber: tenantData['db_id_number'],
        tenantBankBic: tenantData['db_bank_bic'],
        tenantBranchCode: tenantData['db_branch_code'],
        rentAmount: widget.customAmount,
        paymentFrequency: widget.frequency.toLowerCase(),
        startDate: widget.startDate,
        endDate: widget.endDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        noOfInstallments: widget.totalInstallments
      );
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('mandates')
          .add(mandate.toFirestore());
      
      // Show success and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mandate created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back to property details
      Navigator.of(context).popUntil((route) => route.isFirst);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating mandate: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }
  
  void _sharePaymentLink() {
    // Generate payment link (this would typically be a deep link or web link)
    final paymentLink = 'https://payrent.app/pay/${widget.propertyId}/${widget.unit.unitId}';
    
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share Payment Link',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      paymentLink,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Copy to clipboard
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Link copied to clipboard')),
                      );
                    },
                    icon: Icon(Icons.copy),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Share via SMS
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.sms),
                    label: Text('SMS'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Share via Email
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.email),
                    label: Text('Email'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Share via other apps
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.share),
                    label: Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}